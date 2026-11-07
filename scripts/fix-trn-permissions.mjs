#!/usr/bin/env node
// Fix TRN Permissions — ย้ายรถ 84-9318 ไป group 57 + ให้สิทธิ์ user TRN

import axios from '../bellerox-gps-web/node_modules/axios/index.js';

const TRACCAR_URL = 'https://api.centerlink.co.th';

// Helper: Login และ return axios client
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

  try {
    const { data: devices } = await client.get('/api/devices');
    console.log(`✅ Logged in as: ${email}`);
    return client;
  } catch (err) {
    console.error(`❌ Login failed:`, err.response?.data || err.message);
    process.exit(1);
  }
}

async function main() {
  console.log('🔧 Fixing TRN Permissions\n');
  console.log('═'.repeat(60));

  // Login as admin
  console.log('\n1️⃣  Login as admin...');
  const client = await loginTraccar('admin_gpsthailand', 'admin123');

  // Step 1: Get device 376 current data
  console.log('\n2️⃣  Getting device 84-9318 current data...');
  const { data: device } = await client.get('/api/devices/376');
  console.log(`   Current device: ${device.name} (Group: ${device.groupId})`);

  // Step 2: Move device 376 to group 57
  console.log('\n3️⃣  Moving device to group 57...');
  try {
    await client.put('/api/devices/376', {
      ...device,
      groupId: 57,
    });
    console.log('✅ Device moved to group 57!');
  } catch (err) {
    console.error('❌ Failed to move device:', err.response?.data || err.message);
    process.exit(1);
  }

  // Step 4: Grant user TRN (90) permission to group 57
  console.log('\n4️⃣  Granting user TRN (ID: 90) permission to group 57...');
  try {
    await client.post('/api/permissions', {
      userId: 90,
      groupId: 57,
    });
    console.log('✅ Permission granted!');
  } catch (err) {
    // Ignore if already exists
    if (err.response?.status === 400) {
      console.log('⚠️  Permission already exists (OK)');
    } else {
      console.error('❌ Failed to grant permission:', err.response?.data || err.message);
      process.exit(1);
    }
  }

  // Step 5: Verify by logging in as TRN
  console.log('\n5️⃣  Verifying login as TRN...');
  const trnClient = await loginTraccar('TRN', 'abc123456');

  const { data: devices } = await trnClient.get('/api/devices');
  console.log(`   TRN can now see ${devices.length} devices:`);
  devices.forEach((d) => console.log(`   - ${d.name} (ID: ${d.id})`));

  const hasCar = devices.some((d) => d.id === 376);
  if (hasCar) {
    console.log('\n✅ SUCCESS! TRN can now see device 84-9318!');
  } else {
    console.log('\n❌ FAILED! TRN still cannot see device 84-9318.');
    console.log('   Please check Traccar admin manually.');
  }

  console.log('\n═'.repeat(60));
  console.log('✅ Done! Try logging in as TRN:abc123456 now.');
}

main();
