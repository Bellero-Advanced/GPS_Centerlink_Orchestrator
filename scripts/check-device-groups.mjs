#!/usr/bin/env node
// Check exact group assignments for 72-4091 and 84-9318

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
  console.log('🔍 Checking Device Group Assignments\n');
  console.log('═'.repeat(60));

  const client = await loginTraccar('admin_gpsthailand', 'admin123');

  // Get all groups
  const { data: groups } = await client.get('/api/groups');
  const groupMap = new Map(groups.map((g) => [g.id, g.name]));

  // Get all devices
  const { data: devices } = await client.get('/api/devices');

  // Find the 2 devices
  const device1 = devices.find((d) => d.name === '72-4091');
  const device2 = devices.find((d) => d.name === '84-9318');

  console.log('\n📍 Device: 72-4091');
  if (device1) {
    console.log(`   ID: ${device1.id}`);
    console.log(`   IMEI: ${device1.uniqueId}`);
    console.log(`   Group ID: ${device1.groupId}`);
    console.log(`   Group Name: ${groupMap.get(device1.groupId) || 'N/A'}`);
    console.log(`   Status: ${device1.status}`);
  } else {
    console.log('   ❌ NOT FOUND');
  }

  console.log('\n📍 Device: 84-9318');
  if (device2) {
    console.log(`   ID: ${device2.id}`);
    console.log(`   IMEI: ${device2.uniqueId}`);
    console.log(`   Group ID: ${device2.groupId}`);
    console.log(`   Group Name: ${groupMap.get(device2.groupId) || 'N/A'}`);
    console.log(`   Status: ${device2.status}`);
  } else {
    console.log('   ❌ NOT FOUND');
  }

  // Find "ห้างหุ้นส่วนจำกัด ธรณินทร์" group
  console.log('\n🔍 Searching for "ห้างหุ้นส่วนจำกัด ธรณินทร์" groups...');
  const matchingGroups = groups.filter((g) => g.name.includes('ธรณินทร์'));

  console.log(`   Found ${matchingGroups.length} matching groups:\n`);
  matchingGroups.forEach((g) => {
    console.log(`   - ${g.name} (ID: ${g.id})`);

    // Count devices in this group
    const devicesInGroup = devices.filter((d) => d.groupId === g.id);
    console.log(`     ${devicesInGroup.length} devices in this group`);
    devicesInGroup.forEach((d) => {
      console.log(`       • ${d.name} (${d.status})`);
    });
    console.log();
  });

  console.log('═'.repeat(60));
}

main();
