#!/usr/bin/env node
// Fix device group assignments

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
  console.log('🔧 Fixing Device Group Assignments\n');
  console.log('═'.repeat(60));

  const client = await loginTraccar('admin_gpsthailand', 'admin123');

  // Get devices
  console.log('\n1️⃣  Getting current device data...');
  const { data: devices } = await client.get('/api/devices');

  const device72 = devices.find((d) => d.name === '72-4091');
  const device84 = devices.find((d) => d.name === '84-9318');

  if (!device72 || !device84) {
    console.error('❌ Devices not found!');
    process.exit(1);
  }

  console.log(`   72-4091: Currently in Group ${device72.groupId}`);
  console.log(`   84-9318: Currently in Group ${device84.groupId}`);

  // Move 72-4091 to Group 57 (รัชนี บัวน้ำอ้อม)
  console.log('\n2️⃣  Moving 72-4091 to Group 57 (รัชนี บัวน้ำอ้อม)...');
  await client.put(`/api/devices/${device72.id}`, {
    ...device72,
    groupId: 57,
  });
  console.log('   ✅ Moved!');

  // Move 84-9318 to Group 54 (ห้างหุ้นส่วนจำกัด ธรณินทร์ฯ)
  console.log('\n3️⃣  Moving 84-9318 to Group 54 (ห้างหุ้นส่วนจำกัด ธรณินทร์ฯ)...');
  await client.put(`/api/devices/${device84.id}`, {
    ...device84,
    groupId: 54,
  });
  console.log('   ✅ Moved!');

  // Fix TRN user permissions
  console.log('\n4️⃣  Updating TRN user permissions...');

  // TRN should have access to Group 54 (for 84-9318)
  try {
    await client.post('/api/permissions', {
      userId: 90, // TRN user ID
      groupId: 54,
    });
    console.log('   ✅ TRN can now access Group 54');
  } catch (err) {
    if (err.response?.status === 400) {
      console.log('   ℹ️  TRN already has access to Group 54');
    } else {
      throw err;
    }
  }

  // Verify final state
  console.log('\n5️⃣  Verifying final state...');
  const { data: updatedDevices } = await client.get('/api/devices');
  const updated72 = updatedDevices.find((d) => d.name === '72-4091');
  const updated84 = updatedDevices.find((d) => d.name === '84-9318');

  console.log('\n   Final assignments:');
  console.log(`   📍 72-4091 → Group ${updated72.groupId}`);
  console.log(`   📍 84-9318 → Group ${updated84.groupId}`);

  // Verify TRN can see both groups
  console.log('\n6️⃣  Testing TRN login...');
  const trnClient = await loginTraccar('TRN', 'abc123456');
  const { data: trnDevices } = await trnClient.get('/api/devices');

  console.log(`\n   TRN can see ${trnDevices.length} devices:`);
  trnDevices.forEach((d) => {
    console.log(`   - ${d.name} (Group: ${d.groupId})`);
  });

  console.log('\n═'.repeat(60));
  console.log('✅ Done!\n');
}

main().catch((err) => {
  console.error('\n❌ Error:', err.message);
  if (err.response?.data) {
    console.error('Response:', err.response.data);
  }
  process.exit(1);
});
