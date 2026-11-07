#!/usr/bin/env node
// Remove TRN access to Group 57

import axios from '../bellerox-gps-web/node_modules/axios/index.js';

const TRACCAR_URL = 'https://api.centerlink.co.th';

async function loginTraccar(email, password) {
  const auth = Buffer.from(`${email}:${password}`).toString('base64');
  const client = axios.create({
    baseURL: TRACCAR_URL,
    headers: {
      Authorization: `Basic ${auth}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    withCredentials: false,
  });

  await client.get('/api/devices');
  return client;
}

async function main() {
  console.log('🔧 Removing TRN Access to Group 57\n');
  console.log('═'.repeat(60));

  const client = await loginTraccar('admin_gpsthailand', 'admin123');

  console.log('\n1️⃣  Removing TRN (userId: 90) permission to Group 57...');

  try {
    await client.delete('/api/permissions', {
      data: {
        userId: 90,
        groupId: 57,
      },
    });
    console.log('   ✅ Permission removed!');
  } catch (err) {
    if (err.response?.status === 400) {
      console.log('   ℹ️  Permission already removed or does not exist');
    } else {
      throw err;
    }
  }

  // Verify TRN can only see 84-9318 now
  console.log('\n2️⃣  Verifying TRN login...');
  const trnClient = await loginTraccar('TRN', 'abc123456');
  const { data: trnDevices } = await trnClient.get('/api/devices');

  console.log(`\n   TRN can now see ${trnDevices.length} device(s):`);
  trnDevices.forEach((d) => {
    console.log(`   - ${d.name} (Group: ${d.groupId})`);
  });

  console.log('\n═'.repeat(60));
  console.log('✅ Done! TRN should only see 84-9318 now.\n');
}

main().catch((err) => {
  console.error('\n❌ Error:', err.message);
  if (err.response?.data) {
    console.error('Response:', err.response.data);
  }
  process.exit(1);
});
