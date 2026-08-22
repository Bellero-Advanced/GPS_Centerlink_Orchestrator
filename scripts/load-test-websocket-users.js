#!/usr/bin/env node
/**
 * WebSocket Stress Test — Concurrent Users
 *
 * Simulates 10 users subscribing to real-time position updates
 * Tests: WebSocket connection stability, broadcast performance
 *
 * Usage:
 *   TRACCAR_URL=https://traccar.gps.bellerox.com \
 *   TRACCAR_EMAIL=admin@bellerox.com \
 *   TRACCAR_PASSWORD='<admin-password>' \
 *   node load-test-websocket-users.js
 */

const WebSocket = require('ws');
const https = require('https');

// ─── Configuration ────────────────────────────────────────────────────
const TRACCAR_URL = process.env.TRACCAR_URL || 'http://localhost:8082';
const TRACCAR_EMAIL = process.env.TRACCAR_EMAIL || 'admin@bellerox.com';
const TRACCAR_PASSWORD = process.env.TRACCAR_PASSWORD;
if (!TRACCAR_PASSWORD) {
  console.error('TRACCAR_PASSWORD is required — export it, do not hardcode.');
  process.exit(1);
}
const USER_COUNT = 10;
const TEST_DURATION_MIN = 5;

console.log('🧪 WebSocket Stress Test — Concurrent Users');
console.log('═══════════════════════════════════════════════════════════');
console.log(`Traccar API: ${TRACCAR_URL}`);
console.log(`Users: ${USER_COUNT}`);
console.log(`Duration: ${TEST_DURATION_MIN} minutes`);
console.log('═══════════════════════════════════════════════════════════\n');

// ─── Helper: Login & Get Session Cookie ──────────────────────────────
async function login() {
  return new Promise((resolve, reject) => {
    const url = new URL(TRACCAR_URL);
    const postData = `email=${encodeURIComponent(TRACCAR_EMAIL)}&password=${encodeURIComponent(TRACCAR_PASSWORD)}`;

    const options = {
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: '/api/session',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData),
      },
    };

    const client = url.protocol === 'https:' ? https : require('http');

    const req = client.request(options, (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`Login failed: ${res.statusCode}`));
        return;
      }

      const cookies = res.headers['set-cookie'];
      if (!cookies) {
        reject(new Error('No session cookie received'));
        return;
      }

      const sessionCookie = cookies.find(c => c.startsWith('JSESSIONID='));
      if (!sessionCookie) {
        reject(new Error('No JSESSIONID cookie'));
        return;
      }

      resolve(sessionCookie.split(';')[0]);
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

// ─── Simulated User WebSocket Client ──────────────────────────────────
class SimulatedUser {
  constructor(userId, sessionCookie) {
    this.userId = userId;
    this.sessionCookie = sessionCookie;
    this.ws = null;
    this.connected = false;
    this.messagesReceived = 0;
    this.positionsReceived = 0;
    this.devicesReceived = 0;
    this.eventsReceived = 0;
    this.errors = 0;
  }

  connect() {
    return new Promise((resolve, reject) => {
      const wsUrl = TRACCAR_URL.replace('http', 'ws') + '/api/socket';

      this.ws = new WebSocket(wsUrl, {
        headers: {
          Cookie: this.sessionCookie,
        },
      });

      this.ws.on('open', () => {
        this.connected = true;
        console.log(`  ✅ User ${this.userId} connected`);
        resolve();
      });

      this.ws.on('message', (data) => {
        this.messagesReceived++;

        try {
          const message = JSON.parse(data);

          if (message.positions) {
            this.positionsReceived += message.positions.length;
          }
          if (message.devices) {
            this.devicesReceived += message.devices.length;
          }
          if (message.events) {
            this.eventsReceived += message.events.length;
          }
        } catch (err) {
          this.errors++;
        }
      });

      this.ws.on('error', (err) => {
        this.errors++;
        console.error(`  ❌ User ${this.userId} WebSocket error:`, err.message);
      });

      this.ws.on('close', () => {
        this.connected = false;
        console.log(`  🔌 User ${this.userId} disconnected`);
      });

      // Timeout after 10 seconds
      setTimeout(() => {
        if (!this.connected) {
          reject(new Error(`User ${this.userId} connection timeout`));
        }
      }, 10000);
    });
  }

  disconnect() {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
      this.connected = false;
    }
  }

  getStats() {
    return {
      userId: this.userId,
      connected: this.connected,
      messages: this.messagesReceived,
      positions: this.positionsReceived,
      devices: this.devicesReceived,
      events: this.eventsReceived,
      errors: this.errors,
    };
  }
}

// ─── Load Test Runner ─────────────────────────────────────────────────
async function runLoadTest() {
  console.log('🔐 Logging in...');
  const sessionCookie = await login();
  console.log('✅ Session created\n');

  console.log(`👥 Connecting ${USER_COUNT} users...\n`);
  const users = [];

  for (let i = 1; i <= USER_COUNT; i++) {
    const user = new SimulatedUser(i, sessionCookie);
    users.push(user);

    try {
      await user.connect();
      // Small delay between connections
      await new Promise(resolve => setTimeout(resolve, 100));
    } catch (err) {
      console.error(`  ❌ User ${i} failed to connect:`, err.message);
    }
  }

  const connectedUsers = users.filter(u => u.connected).length;
  console.log(`\n✅ ${connectedUsers}/${USER_COUNT} users connected`);

  if (connectedUsers === 0) {
    console.error('\n❌ No users connected. Exiting.');
    process.exit(1);
  }

  console.log(`\n📊 Monitoring for ${TEST_DURATION_MIN} minutes...`);
  console.log('   Press Ctrl+C to stop\n');

  // Print stats every 10 seconds
  const statsInterval = setInterval(() => {
    console.log('\n─────────────────────────────────────────────────────');
    console.log(`Time: ${new Date().toISOString()}`);
    console.log('─────────────────────────────────────────────────────');

    let totalMessages = 0;
    let totalPositions = 0;
    let totalErrors = 0;
    let activeConnections = 0;

    users.forEach(user => {
      const stats = user.getStats();
      totalMessages += stats.messages;
      totalPositions += stats.positions;
      totalErrors += stats.errors;
      if (stats.connected) activeConnections++;

      console.log(`User ${stats.userId}: ${stats.messages} msgs, ${stats.positions} pos, ${stats.errors} errors`);
    });

    console.log('─────────────────────────────────────────────────────');
    console.log(`Total: ${totalMessages} messages, ${totalPositions} positions`);
    console.log(`Active: ${activeConnections}/${USER_COUNT} users`);
    console.log(`Errors: ${totalErrors}`);
    console.log('─────────────────────────────────────────────────────');
  }, 10000);

  // Stop after test duration
  setTimeout(() => {
    console.log('\n\n🛑 Test duration complete. Stopping...');
    clearInterval(statsInterval);

    console.log('\nDisconnecting users...');
    users.forEach(u => u.disconnect());

    // Final stats
    setTimeout(() => {
      console.log('\n📊 Final Test Results:');
      console.log('═══════════════════════════════════════════════════════════');

      let totalMessages = 0;
      let totalPositions = 0;
      let totalDevices = 0;
      let totalEvents = 0;
      let totalErrors = 0;

      users.forEach(user => {
        const stats = user.getStats();
        totalMessages += stats.messages;
        totalPositions += stats.positions;
        totalDevices += stats.devices;
        totalEvents += stats.events;
        totalErrors += stats.errors;
      });

      console.log(`Users Connected: ${USER_COUNT}`);
      console.log(`Test Duration: ${TEST_DURATION_MIN} minutes`);
      console.log(`\nTotal Messages: ${totalMessages}`);
      console.log(`Total Positions: ${totalPositions}`);
      console.log(`Total Devices: ${totalDevices}`);
      console.log(`Total Events: ${totalEvents}`);
      console.log(`Total Errors: ${totalErrors}`);

      const avgMessagesPerUser = (totalMessages / USER_COUNT).toFixed(1);
      const avgPositionsPerUser = (totalPositions / USER_COUNT).toFixed(1);
      const messagesPerMinute = (totalMessages / TEST_DURATION_MIN).toFixed(1);

      console.log(`\nAvg Messages/User: ${avgMessagesPerUser}`);
      console.log(`Avg Positions/User: ${avgPositionsPerUser}`);
      console.log(`Messages/Min: ${messagesPerMinute}`);

      const successRate = totalErrors === 0 ? 100 : ((totalMessages / (totalMessages + totalErrors)) * 100).toFixed(2);
      console.log(`Success Rate: ${successRate}%`);

      console.log('═══════════════════════════════════════════════════════════');

      if (totalErrors === 0 && totalMessages > 0) {
        console.log('\n✅ PASS: WebSocket stress test successful');
      } else if (totalErrors > 0) {
        console.log('\n⚠️  WARNING: Errors detected during test');
      } else {
        console.log('\n❌ FAIL: No messages received');
      }

      process.exit(0);
    }, 2000);
  }, TEST_DURATION_MIN * 60 * 1000);

  // Handle Ctrl+C
  process.on('SIGINT', () => {
    console.log('\n\n🛑 Test interrupted by user');
    clearInterval(statsInterval);
    users.forEach(u => u.disconnect());
    setTimeout(() => process.exit(0), 2000);
  });
}

// ─── Run ──────────────────────────────────────────────────────────────
runLoadTest().catch(err => {
  console.error('\n❌ Load test failed:', err.message);
  process.exit(1);
});
