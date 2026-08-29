#!/usr/bin/env node
// ═══════════════════════════════════════════════════════
// Fix GT06 Timezone — Set decoder.timezone per device
// Usage: TRACCAR_USER=admin TRACCAR_PASS=xxx node fix-gt06-timezone.js
// ═══════════════════════════════════════════════════════

const axios = require('axios');

const API_URL = process.env.TRACCAR_API_URL || 'https://api.centerlink.co.th';
const USER = process.env.TRACCAR_USER;
const PASS = process.env.TRACCAR_PASS;

if (!USER || !PASS) {
  console.error('❌ Missing TRACCAR_USER or TRACCAR_PASS');
  process.exit(1);
}

const client = axios.create({
  baseURL: API_URL,
  auth: { username: USER, password: PASS },
  headers: { 'Content-Type': 'application/json' },
});

// GT06 devices ที่ต้องแก้ (จากการสำรวจ)
const GT06_DEVICES = [
  128, 229, 219, 123, 248, 220, 242, 136, 91, 205,
  80, 142, 116, 180, 69, 88, 117
];

async function fixDevice(deviceId) {
  try {
    // 1. ดึง device ปัจจุบัน
    const { data: device } = await client.get(`/api/devices/${deviceId}`);

    // 2. เพิ่ม decoder.timezone attribute
    const updated = {
      ...device,
      attributes: {
        ...device.attributes,
        'decoder.timezone': '-07:00',
      },
    };

    // 3. Update device
    await client.put(`/api/devices/${deviceId}`, updated);

    console.log(`✅ Device ${deviceId} (${device.name}): decoder.timezone = -07:00`);
    return { deviceId, name: device.name, success: true };
  } catch (err) {
    console.error(`❌ Device ${deviceId}: ${err.message}`);
    return { deviceId, success: false, error: err.message };
  }
}

async function main() {
  console.log('🔧 Fix GT06 Timezone — Per-Device Attribute\n');
  console.log(`API: ${API_URL}`);
  console.log(`User: ${USER}`);
  console.log(`Devices: ${GT06_DEVICES.length}\n`);

  const results = [];

  for (const deviceId of GT06_DEVICES) {
    const result = await fixDevice(deviceId);
    results.push(result);

    // Delay 200ms ระหว่าง request เพื่อไม่ overwhelm server
    await new Promise(r => setTimeout(r, 200));
  }

  console.log('\n📊 Summary:');
  const success = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;
  console.log(`✅ Success: ${success}/${GT06_DEVICES.length}`);
  console.log(`❌ Failed: ${failed}`);

  if (failed > 0) {
    console.log('\nFailed devices:');
    results.filter(r => !r.success).forEach(r => {
      console.log(`  - Device ${r.deviceId}: ${r.error}`);
    });
  }
}

main().catch(err => {
  console.error('💥 Fatal error:', err);
  process.exit(1);
});
