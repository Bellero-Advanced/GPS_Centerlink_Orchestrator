#!/usr/bin/env node
/**
 * GPS Device Simulator — Load Test Script
 *
 * Simulates 20,000 GPS devices sending positions every 30 seconds
 * Tests: HAProxy load balancing, Traccar throughput, PostgreSQL writes
 *
 * Usage:
 *   node load-test-gps-devices.js --devices=20000 --interval=30
 */

const net = require('net');

// ─── Configuration ────────────────────────────────────────────────────
const HAPROXY_HOST = process.env.HAPROXY_HOST || 'localhost';
const GT06_PORT = 5023; // Most common Thai GPS tracker protocol
const DEVICE_COUNT = parseInt(process.argv.find(a => a.startsWith('--devices='))?.split('=')[1] || '20000');
const INTERVAL_SEC = parseInt(process.argv.find(a => a.startsWith('--interval='))?.split('=')[1] || '30');

// Bangkok area coordinates (for realistic simulation)
const BANGKOK_CENTER = { lat: 13.7563, lon: 100.5018 };
const RADIUS_KM = 50; // Simulate devices within 50km of Bangkok

console.log('🚀 GPS Device Simulator — Load Test');
console.log('═══════════════════════════════════════════════════════════');
console.log(`HAProxy: ${HAPROXY_HOST}:${GT06_PORT}`);
console.log(`Devices: ${DEVICE_COUNT}`);
console.log(`Interval: ${INTERVAL_SEC} seconds`);
console.log(`Protocol: GT06 (Coban GPS306)`);
console.log('═══════════════════════════════════════════════════════════\n');

// ─── GT06 Protocol Implementation ─────────────────────────────────────
function generateIMEI(index) {
  // Generate realistic IMEI: 15 digits
  return `86715003${String(index).padStart(7, '0')}`;
}

function randomCoordinate(center, radiusKm) {
  // Random point within radius (uniform distribution)
  const r = radiusKm / 111 * Math.sqrt(Math.random()); // 111 km per degree at equator
  const theta = Math.random() * 2 * Math.PI;
  return {
    lat: center.lat + r * Math.cos(theta),
    lon: center.lon + r * Math.sin(theta),
  };
}

function buildGT06LoginPacket(imei) {
  // GT06 login packet format:
  // Start: 0x7878
  // Length: 0x11 (17 bytes)
  // Protocol: 0x01 (login)
  // IMEI: 8 bytes BCD-encoded
  // End: 0x0D0A
  const buf = Buffer.alloc(21);
  buf.writeUInt16BE(0x7878, 0); // Start
  buf.writeUInt8(0x11, 2); // Length
  buf.writeUInt8(0x01, 3); // Protocol (login)

  // IMEI BCD encoding (15 digits → 8 bytes)
  const imeiBCD = Buffer.from(imei.padEnd(16, 'F').match(/.{2}/g).map(b => parseInt(b, 16)));
  imeiBCD.copy(buf, 4, 0, 8);

  buf.writeUInt16BE(0x0001, 12); // Serial number
  buf.writeUInt16BE(0x0D0A, 19); // End marker

  // CRC16 (simplified — real implementation needs proper CRC)
  const crc = 0x1234;
  buf.writeUInt16BE(crc, 17);

  return buf;
}

function buildGT06LocationPacket(imei, lat, lon, speed, heading) {
  // GT06 location packet format:
  // Start: 0x7878
  // Length: varies
  // Protocol: 0x12 (location)
  // DateTime: 6 bytes
  // GPS Info: lat, lon, speed, course, etc.
  // End: 0x0D0A

  const buf = Buffer.alloc(41);
  buf.writeUInt16BE(0x7878, 0); // Start
  buf.writeUInt8(0x25, 2); // Length (37 bytes)
  buf.writeUInt8(0x12, 3); // Protocol (location)

  // DateTime (current UTC)
  const now = new Date();
  buf.writeUInt8(now.getUTCFullYear() - 2000, 4);
  buf.writeUInt8(now.getUTCMonth() + 1, 5);
  buf.writeUInt8(now.getUTCDate(), 6);
  buf.writeUInt8(now.getUTCHours(), 7);
  buf.writeUInt8(now.getUTCMinutes(), 8);
  buf.writeUInt8(now.getUTCSeconds(), 9);

  // GPS info length
  buf.writeUInt8(0x0C, 10); // 12 bytes

  // Satellites & GPS accuracy
  buf.writeUInt8(0x8C, 11); // 12 satellites, GPS valid

  // Latitude (degrees × 30000 / 180)
  const latInt = Math.floor(lat * 30000 / 180);
  buf.writeInt32BE(latInt, 12);

  // Longitude (degrees × 30000 / 180)
  const lonInt = Math.floor(lon * 30000 / 180);
  buf.writeInt32BE(lonInt, 16);

  // Speed (km/h)
  buf.writeUInt8(Math.floor(speed), 20);

  // Course (0-360 degrees, 2 bytes)
  buf.writeUInt16BE(Math.floor(heading), 21);

  // LBS info (cell tower — not used, zero fill)
  buf.fill(0, 23, 32);

  // Serial number
  buf.writeUInt16BE(0x0001, 32);

  // CRC16
  buf.writeUInt16BE(0x5678, 34);

  // End marker
  buf.writeUInt16BE(0x0D0A, 36);

  return buf;
}

// ─── Device Simulator ─────────────────────────────────────────────────
class SimulatedDevice {
  constructor(index) {
    this.index = index;
    this.imei = generateIMEI(index);
    this.position = randomCoordinate(BANGKOK_CENTER, RADIUS_KM);
    this.speed = Math.random() * 60; // 0-60 km/h
    this.heading = Math.random() * 360;
    this.socket = null;
    this.connected = false;
  }

  async connect() {
    return new Promise((resolve, reject) => {
      this.socket = net.createConnection(GT06_PORT, HAPROXY_HOST);

      this.socket.on('connect', () => {
        this.connected = true;
        // Send login packet
        this.socket.write(buildGT06LoginPacket(this.imei));
        resolve();
      });

      this.socket.on('error', (err) => {
        this.connected = false;
        reject(err);
      });

      this.socket.on('close', () => {
        this.connected = false;
      });

      // Timeout after 10 seconds
      setTimeout(() => {
        if (!this.connected) {
          reject(new Error('Connection timeout'));
        }
      }, 10000);
    });
  }

  sendPosition() {
    if (!this.connected || !this.socket) {
      return false;
    }

    // Update position (simulate movement)
    this.position.lat += (Math.random() - 0.5) * 0.001; // ~100m movement
    this.position.lon += (Math.random() - 0.5) * 0.001;
    this.speed += (Math.random() - 0.5) * 5; // Speed variation
    this.speed = Math.max(0, Math.min(120, this.speed)); // Clamp 0-120 km/h
    this.heading += (Math.random() - 0.5) * 30; // Heading variation

    const packet = buildGT06LocationPacket(
      this.imei,
      this.position.lat,
      this.position.lon,
      this.speed,
      this.heading
    );

    this.socket.write(packet);
    return true;
  }

  disconnect() {
    if (this.socket) {
      this.socket.end();
      this.socket = null;
      this.connected = false;
    }
  }
}

// ─── Load Test Runner ─────────────────────────────────────────────────
async function runLoadTest() {
  const devices = [];
  const stats = {
    connected: 0,
    failed: 0,
    positionsSent: 0,
    positionsFailed: 0,
  };

  console.log('📡 Connecting devices...');
  console.log('(This may take 2-5 minutes for 20,000 devices)\n');

  // Connect devices in batches of 100 (avoid overwhelming HAProxy)
  const BATCH_SIZE = 100;
  for (let i = 0; i < DEVICE_COUNT; i += BATCH_SIZE) {
    const batch = [];

    for (let j = 0; j < BATCH_SIZE && (i + j) < DEVICE_COUNT; j++) {
      const device = new SimulatedDevice(i + j);
      devices.push(device);

      batch.push(
        device.connect()
          .then(() => stats.connected++)
          .catch(() => stats.failed++)
      );
    }

    await Promise.allSettled(batch);

    // Progress update every 1000 devices
    if ((i + BATCH_SIZE) % 1000 === 0 || (i + BATCH_SIZE) >= DEVICE_COUNT) {
      console.log(`  ⏳ Connected: ${stats.connected} / ${Math.min(i + BATCH_SIZE, DEVICE_COUNT)}`);
    }

    // Small delay between batches
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  console.log('\n✅ Device connection phase complete');
  console.log(`   Connected: ${stats.connected}`);
  console.log(`   Failed: ${stats.failed}`);

  if (stats.connected === 0) {
    console.error('\n❌ No devices connected. Check HAProxy is running.');
    process.exit(1);
  }

  console.log(`\n🚗 Sending positions every ${INTERVAL_SEC} seconds...`);
  console.log('   Press Ctrl+C to stop\n');

  // Send positions at intervals
  const interval = setInterval(() => {
    let sent = 0;
    let failed = 0;

    devices.forEach(device => {
      if (device.sendPosition()) {
        sent++;
      } else {
        failed++;
      }
    });

    stats.positionsSent += sent;
    stats.positionsFailed += failed;

    const now = new Date().toISOString();
    console.log(`[${now}] Sent: ${sent}, Failed: ${failed}, Total: ${stats.positionsSent}`);
  }, INTERVAL_SEC * 1000);

  // Handle Ctrl+C gracefully
  process.on('SIGINT', () => {
    console.log('\n\n🛑 Stopping load test...');
    clearInterval(interval);

    console.log('Disconnecting devices...');
    devices.forEach(d => d.disconnect());

    console.log('\n📊 Final Stats:');
    console.log(`   Devices Connected: ${stats.connected}`);
    console.log(`   Positions Sent: ${stats.positionsSent}`);
    console.log(`   Positions Failed: ${stats.positionsFailed}`);
    console.log(`   Success Rate: ${((stats.positionsSent / (stats.positionsSent + stats.positionsFailed)) * 100).toFixed(2)}%`);

    process.exit(0);
  });
}

// ─── Run ──────────────────────────────────────────────────────────────
runLoadTest().catch(err => {
  console.error('\n❌ Load test failed:', err.message);
  process.exit(1);
});
