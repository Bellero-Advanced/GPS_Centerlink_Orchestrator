// ═══════════════════════════════════════════════════════
// overdue-checker — Supabase Edge Function
// Scheduled: 02:00 UTC daily (= 09:00 Bangkok, GMT+7)
// Schedule: supabase/config.toml  [functions.overdue-checker]
//           schedule = "0 2 * * *"
//
// Logic:
//   1. Mark subscriptions as 'overdue' (1–3 days past end_date)
//   2. Lock subscriptions + Traccar devices (> 3 days past end_date)
//
// Secrets required (supabase secrets set):
//   TRACCAR_API_URL        e.g. https://api.gps.bellerox.com
//   TRACCAR_ADMIN_EMAIL    Traccar admin account email
//   TRACCAR_ADMIN_PASSWORD Traccar admin account password
// ═══════════════════════════════════════════════════════

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const TRACCAR_URL   = Deno.env.get("TRACCAR_API_URL") ?? "";
const TRACCAR_EMAIL = Deno.env.get("TRACCAR_ADMIN_EMAIL") ?? "";
const TRACCAR_PASS  = Deno.env.get("TRACCAR_ADMIN_PASSWORD") ?? "";
const TRACCAR_AUTH  = btoa(`${TRACCAR_EMAIL}:${TRACCAR_PASS}`);

/** Disable a device in Traccar (full object must be fetched first). */
async function lockTraccarDevice(deviceId: number): Promise<void> {
  const getRes = await fetch(`${TRACCAR_URL}/api/devices/${deviceId}`, {
    headers: { Authorization: `Basic ${TRACCAR_AUTH}` },
  });
  if (!getRes.ok) {
    console.warn(`[overdue-checker] GET device ${deviceId} failed: ${getRes.status}`);
    return;
  }
  const device = await getRes.json();
  const putRes = await fetch(`${TRACCAR_URL}/api/devices/${deviceId}`, {
    method: "PUT",
    headers: {
      Authorization: `Basic ${TRACCAR_AUTH}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ ...device, disabled: true }),
  });
  if (!putRes.ok) {
    console.warn(`[overdue-checker] PUT disable device ${deviceId} failed: ${putRes.status}`);
  }
}

Deno.serve(async (_req: Request) => {
  const now = new Date();
  const today = now.toISOString().split("T")[0];

  // ── 1. Mark overdue (past end_date but ≤ 3 days) ──────────────────
  const threeDaysAgo = new Date(now.getTime() - 3 * 86_400_000)
    .toISOString().split("T")[0];

  const { error: overdueErr } = await supabase
    .from("billing_subscriptions")
    .update({ status: "overdue", updated_at: now.toISOString() })
    .lt("end_date", today)
    .gte("end_date", threeDaysAgo)
    .eq("status", "active");

  if (overdueErr) console.error("[overdue-checker] overdue update error:", overdueErr);

  // ── 2. Lock subscriptions > 3 days past end_date ──────────────────
  const { data: toLock, error: fetchErr } = await supabase
    .from("billing_subscriptions")
    .select("id, device_id")
    .lt("end_date", threeDaysAgo)
    .in("status", ["active", "overdue", "pending"]);

  if (fetchErr) {
    console.error("[overdue-checker] fetch toLock error:", fetchErr);
    return new Response(JSON.stringify({ error: fetchErr.message }), { status: 500 });
  }

  let locked = 0;
  for (const row of (toLock ?? [])) {
    // Lock in Traccar
    await lockTraccarDevice(row.device_id as number);
    // Update DB status
    await supabase
      .from("billing_subscriptions")
      .update({ status: "locked", updated_at: now.toISOString() })
      .eq("id", row.id);
    locked++;
  }

  const result = { checked: now.toISOString(), locked, overdueMarked: true };
  console.log("[overdue-checker]", result);
  return new Response(JSON.stringify(result), {
    headers: { "Content-Type": "application/json" },
  });
});
