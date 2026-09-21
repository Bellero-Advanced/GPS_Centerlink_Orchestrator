import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// ============================================================================
// DLT Manual Override Batch Sender
// Runs every 60s via pg_cron → merges manual overrides + live GPS → sends to DLT
// ============================================================================

interface DltLocation {
  driver_id: string;
  unit_id: string;
  seq: number;
  utc_ts: string;
  recv_utc_ts: string;
  lat: number;
  lon: number;
  alt: number;
  speed: number;
  engine_status: number;
  fix: number;
  license: string;
  course: number;
  hdop: number;
  num_sats: number;
  gsm_cell: number;
  gsm_loc: number;
  gsm_rssi: number;
  mileage: number;
  ext_power_status: number;
  ext_power: number;
  high_acc_count: number;
  high_de_acc_count: number;
  over_speed_count: number;
  max_speed: number;
}

interface DltPayload {
  vender_id: number;
  locations_count: number;
  locations: DltLocation[];
}

interface ManualOverride {
  id: string;
  device_id: number;
  latitude: number;
  longitude: number;
  status: string;
  speed_kmh: number;
  course: number;
  reason: string;
  created_by: string;
  created_at: string;
}

interface TraccarDevice {
  id: number;
  uniqueId: string;
  attributes?: {
    dltUnitId?: string;
    gpsModelId?: string;
    dltModelId?: string;
    driverLicenseNo?: string;
  };
}

interface DltConfig {
  venderId: number;
  username: string;
  password: string;
  serviceUrl: string;
}

// ============================================================================
// Helper: Build DLT unit_id (copied from dltService.ts:296-322)
// ============================================================================

function buildDltUnitId(device: TraccarDevice, venderId: number): string {
  // Priority 1: User-provided dltUnitId override
  if (device.attributes?.dltUnitId?.trim()) {
    return device.attributes.dltUnitId.trim();
  }

  // Priority 2: Auto-calculate from gpsModelId + IMEI
  const modelId: string =
    device.attributes?.gpsModelId
      ? device.attributes.gpsModelId.replace(/\D/g, "").slice(0, 7).padStart(7, "0")
      : device.attributes?.dltModelId
        ? device.attributes.dltModelId.replace(/\D/g, "").slice(0, 7).padStart(7, "0")
        : String(venderId).padStart(3, "0") + "0000";

  const imei = device.uniqueId.replace(/\D/g, "").slice(0, 15).padStart(15, "0");
  const padding = "00000"; // 5 zeros between model and IMEI

  return modelId + padding + imei; // 27 digits total
}

// ============================================================================
// Helper: Build manual DltLocation from override
// ============================================================================

function buildManualLocation(
  override: ManualOverride,
  device: TraccarDevice,
  venderId: number,
  seq: number,
): DltLocation {
  const unitId = buildDltUnitId(device, venderId);
  const license = unitId.padEnd(80, "0");
  const now = new Date().toISOString();

  // Map status to engine_status
  const engineStatus = override.status === "stopped" ? 0 : 1;
  const speed = override.status === "idle" ? 0 : override.speed_kmh;

  return {
    driver_id: device.attributes?.driverLicenseNo?.trim() || "",
    unit_id: unitId,
    seq,
    utc_ts: now,
    recv_utc_ts: now,
    lat: override.latitude,
    lon: override.longitude,
    alt: 0,
    speed,
    engine_status: engineStatus,
    fix: 1,
    license,
    course: override.course,
    hdop: 2,
    num_sats: 0,
    gsm_cell: 0,
    gsm_loc: 0,
    gsm_rssi: 0,
    mileage: 0,
    ext_power_status: 0,
    ext_power: 0,
    high_acc_count: 0,
    high_de_acc_count: 0,
    over_speed_count: speed > 120 ? 1 : 0,
    max_speed: speed,
  };
}

// ============================================================================
// Helper: Validate DltLocation
// ============================================================================

function validateLocation(loc: DltLocation): string | null {
  if (!/^\d{27}$/.test(loc.unit_id)) {
    return `unit_id must be 27 digits, got: ${loc.unit_id}`;
  }
  if (!/[A-Z]/.test(loc.license)) {
    return `license must contain A-Z, got: ${loc.license}`;
  }
  if (loc.lat < -90 || loc.lat > 90) {
    return `latitude out of range: ${loc.lat}`;
  }
  if (loc.lon < -180 || loc.lon > 180) {
    return `longitude out of range: ${loc.lon}`;
  }
  return null;
}

// ============================================================================
// Main Handler
// ============================================================================

Deno.serve(async (req: Request) => {
  const startTime = Date.now();
  console.log("=== send-dlt-batch: START ===");

  try {
    // Environment variables
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const TRACCAR_API_URL = Deno.env.get("TRACCAR_API_URL") || "https://api.centerlink.co.th";
    const TRACCAR_EMAIL = Deno.env.get("TRACCAR_EMAIL");
    const TRACCAR_PASSWORD = Deno.env.get("TRACCAR_PASSWORD");
    const WORKER_URL = Deno.env.get("WORKER_URL") || "https://api.centerlink.co.th";

    if (!TRACCAR_EMAIL || !TRACCAR_PASSWORD) {
      throw new Error("Missing TRACCAR_EMAIL or TRACCAR_PASSWORD");
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Step 1: Read active manual overrides
    const { data: overrides, error: overridesError } = await supabase
      .from("dlt_manual_overrides")
      .select("*")
      .eq("is_active", true);

    if (overridesError) throw overridesError;

    console.log(`Found ${overrides?.length || 0} active manual overrides`);

    if (!overrides || overrides.length === 0) {
      console.log("No active overrides, skipping batch");
      return new Response(JSON.stringify({ message: "No active overrides" }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      });
    }

    // Step 2: Read DLT config from Traccar user (id=1)
    const traccarAuth = btoa(`${TRACCAR_EMAIL}:${TRACCAR_PASSWORD}`);
    const userRes = await fetch(`${TRACCAR_API_URL}/api/users/1`, {
      headers: { Authorization: `Basic ${traccarAuth}` },
    });

    if (!userRes.ok) {
      throw new Error(`Traccar user fetch failed: ${userRes.status}`);
    }

    const user = await userRes.json();
    const dltConfigStr = user.attributes?.dltConfig;

    if (!dltConfigStr) {
      throw new Error("DLT config not found in user attributes");
    }

    const dltConfig: DltConfig = JSON.parse(dltConfigStr);
    console.log(`DLT config loaded: venderId=${dltConfig.venderId}`);

    // Step 3: Fetch device details for all override devices
    const deviceIds = overrides.map((o) => o.device_id);
    const devicesRes = await fetch(`${TRACCAR_API_URL}/api/devices`, {
      headers: { Authorization: `Basic ${traccarAuth}` },
    });

    if (!devicesRes.ok) {
      throw new Error(`Traccar devices fetch failed: ${devicesRes.status}`);
    }

    const allDevices: TraccarDevice[] = await devicesRes.json();
    const deviceMap = new Map(allDevices.map((d) => [d.id, d]));

    // Step 4: Build manual locations
    const locations: DltLocation[] = [];
    const manualDeviceIds: number[] = [];
    let seq = Math.floor(Math.random() * 1000);

    for (const override of overrides) {
      const device = deviceMap.get(override.device_id);
      if (!device) {
        console.warn(`Device ${override.device_id} not found, skipping`);
        continue;
      }

      const location = buildManualLocation(override, device, dltConfig.venderId, seq++);
      const validationError = validateLocation(location);

      if (validationError) {
        console.warn(`Invalid location for device ${override.device_id}: ${validationError}`);
        continue;
      }

      locations.push(location);
      manualDeviceIds.push(override.device_id);
    }

    if (locations.length === 0) {
      console.log("No valid locations to send");
      return new Response(JSON.stringify({ message: "No valid locations" }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      });
    }

    // Step 5: Build DLT payload
    const payload: DltPayload = {
      vender_id: dltConfig.venderId,
      locations_count: locations.length,
      locations,
    };

    console.log(`Sending ${locations.length} manual locations to DLT`);

    // Step 6: Send to DLT via Worker
    const dltAuth = btoa(`${dltConfig.username}:${dltConfig.password}`);
    const dltRes = await fetch(`${WORKER_URL}/dlt/gps/add/locations`, {
      method: "POST",
      headers: {
        Authorization: `Basic ${dltAuth}`,
        "Content-Type": "application/json; charset=utf-8",
      },
      body: JSON.stringify(payload),
    });

    const responseBody = await dltRes.text();
    let responseJson = null;
    try {
      responseJson = JSON.parse(responseBody);
    } catch {
      responseJson = { raw: responseBody };
    }

    const success = dltRes.ok;
    console.log(`DLT response: ${dltRes.status} ${success ? "✓" : "✗"}`);

    // Step 7: Log transmission
    const { error: logError } = await supabase.from("dlt_transmission_log").insert({
      batch: payload,
      response: responseJson,
      http_status: dltRes.status,
      success,
      error_message: success ? null : responseBody.slice(0, 500),
      manual_device_ids: manualDeviceIds,
    });

    if (logError) {
      console.error("Failed to log transmission:", logError);
    }

    const duration = Date.now() - startTime;
    console.log(`=== send-dlt-batch: END (${duration}ms) ===`);

    return new Response(
      JSON.stringify({
        success,
        locations_sent: locations.length,
        manual_device_ids: manualDeviceIds,
        dlt_status: dltRes.status,
        response: responseJson,
        duration_ms: duration,
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: success ? 200 : 500,
      },
    );
  } catch (error) {
    console.error("send-dlt-batch ERROR:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 500,
      },
    );
  }
});
