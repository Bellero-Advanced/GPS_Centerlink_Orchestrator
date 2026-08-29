// ═══════════════════════════════════════════════════════
// Production Diagnostic Script — Check Specific Customer
// Query Traccar API for "สมาท คอนกรีต" vehicles
// Detect online-but-stale paradox
// ═══════════════════════════════════════════════════════

const https = require('https');
const http = require('http');

const TRACCAR_URL = process.env.TRACCAR_URL || 'https://traccar.gps.bellerox.com';
const TRACCAR_EMAIL = process.env.TRACCAR_EMAIL || 'admin@example.com';
const TRACCAR_PASSWORD = process.env.TRACCAR_PASSWORD || '';

const GPS_STALE_MS = 10 * 60 * 1000; // 10 minutes

function httpsGet(url: string, headers: Record<string, string>): Promise<any> {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const req = client.get(url, { headers }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          reject(new Error('Invalid JSON response'));
        }
      });
    });
    req.on('error', reject);
  });
}

async function checkCustomerVehicles(customerName: string) {
  console.log(`\n🔍 Checking vehicles for: ${customerName}\n`);

  // Login to Traccar
  const auth = Buffer.from(`${TRACCAR_EMAIL}:${TRACCAR_PASSWORD}`).toString('base64');
  const headers = { Authorization: `Basic ${auth}` };

  try {
    // Get all devices
    const allDevices = await httpsGet(`${TRACCAR_URL}/api/devices`, headers);

    // Filter by customer name (check device name, contact, or attributes)
    const customerDevices = allDevices.filter((d: any) => {
      const nameMatch = d.name?.toLowerCase().includes(customerName.toLowerCase());
      const contactMatch = d.contact?.toLowerCase().includes(customerName.toLowerCase());
      const attrMatch = JSON.stringify(d.attributes || {}).toLowerCase().includes(customerName.toLowerCase());
      return nameMatch || contactMatch || attrMatch;
    });

    console.log(`📊 Found ${customerDevices.length} devices for "${customerName}"\n`);

    if (customerDevices.length === 0) {
      console.log('❌ No devices found. Try searching without Thai characters or check spelling.');
      return;
    }

    // Get current positions
    const positions = await httpsGet(`${TRACCAR_URL}/api/positions`, headers);
    const positionMap = new Map(positions.map((p: any) => [p.deviceId, p]));

    // Analyze each device
    const now = Date.now();
    const paradoxVehicles = [];
    const normalVehicles = [];
    const offlineVehicles = [];

    for (const device of customerDevices) {
      const position = positionMap.get(device.id);
      const status = device.status;
      const lastUpdate = device.lastUpdate ? new Date(device.lastUpdate).getTime() : null;
      const positionAge = position ? now - new Date(position.fixTime).getTime() : null;

      const record = {
        id: device.id,
        name: device.name,
        status: status,
        lastUpdate: device.lastUpdate,
        positionAge: positionAge ? Math.round(positionAge / 1000 / 60) : null, // minutes
        hasPosition: !!position,
        lat: position?.latitude?.toFixed(5),
        lng: position?.longitude?.toFixed(5),
        speed: position?.speed ? Math.round(position.speed * 1.852) : 0, // knots to km/h
      };

      // Categorize
      if (status === 'online' && positionAge && positionAge > GPS_STALE_MS) {
        // PARADOX: Online but stale position
        paradoxVehicles.push(record);
      } else if (status === 'online') {
        // Normal online
        normalVehicles.push(record);
      } else {
        // Offline
        offlineVehicles.push(record);
      }
    }

    // Report
    console.log('═══════════════════════════════════════════════════\n');
    console.log(`🚨 PARADOX VEHICLES (Online but stale > 10 min): ${paradoxVehicles.length}\n`);

    if (paradoxVehicles.length > 0) {
      console.log('These vehicles show as online but coordinates are frozen:\n');
      paradoxVehicles.forEach((v: any) => {
        console.log(`  🔴 ${v.name} (ID: ${v.id})`);
        console.log(`     Status: ${v.status}`);
        console.log(`     Position age: ${v.positionAge} minutes`);
        console.log(`     Last GPS: ${v.lat}, ${v.lng}`);
        console.log(`     Speed: ${v.speed} km/h`);
        console.log('');
      });
    }

    console.log('─────────────────────────────────────────────────\n');
    console.log(`✅ NORMAL VEHICLES (Online with fresh position): ${normalVehicles.length}\n`);

    if (normalVehicles.length > 0) {
      normalVehicles.slice(0, 5).forEach((v: any) => {
        console.log(`  🟢 ${v.name} (ID: ${v.id}) — ${v.positionAge} min ago`);
      });
      if (normalVehicles.length > 5) {
        console.log(`  ... and ${normalVehicles.length - 5} more`);
      }
      console.log('');
    }

    console.log('─────────────────────────────────────────────────\n');
    console.log(`⚫ OFFLINE VEHICLES: ${offlineVehicles.length}\n`);

    if (offlineVehicles.length > 0) {
      offlineVehicles.slice(0, 5).forEach((v: any) => {
        console.log(`  ⚫ ${v.name} (ID: ${v.id}) — ${v.positionAge ? `${v.positionAge} min` : 'never reported'}`);
      });
      if (offlineVehicles.length > 5) {
        console.log(`  ... and ${offlineVehicles.length - 5} more`);
      }
      console.log('');
    }

    console.log('═══════════════════════════════════════════════════\n');

    // Diagnosis
    if (paradoxVehicles.length > 0) {
      console.log('⚠️  DIAGNOSIS:\n');
      console.log('These vehicles are affected by the WebSocket position cache gap.');
      console.log('The fix deployed today (093b577) should resolve this within 10 seconds.\n');
      console.log('📋 Next Steps:');
      console.log('1. Wait 10 seconds (emergency polling should kick in)');
      console.log('2. Refresh the map page');
      console.log('3. Check if positions update');
      console.log('4. If still frozen, check console logs for:');
      console.log('   [Emergency Refresh] X vehicles in stale-online paradox\n');
    } else {
      console.log('✅ All online vehicles have fresh positions!');
      console.log('The fix is working correctly.\n');
    }

  } catch (err: any) {
    console.error('❌ Error querying Traccar:', err.message);
  }
}

// Run
const customerName = process.argv[2] || 'สมาท';
checkCustomerVehicles(customerName).catch(console.error);
