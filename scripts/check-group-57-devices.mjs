#!/usr/bin/env node
// Check all devices in group 57

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
  console.log('🔍 Checking Group 57 Devices\n');
  console.log('═'.repeat(60));

  const client = await loginTraccar('admin_gpsthailand', 'admin123');

  // Get group 57 info
  console.log('\n1️⃣  Getting group 57 info...');
  const { data: groups } = await client.get('/api/groups');
  const group57 = groups.find((g) => g.id === 57);

  if (!group57) {
    console.error('❌ Group 57 not found!');
    process.exit(1);
  }

  console.log(`✅ Group: ${group57.name} (ID: ${group57.id})`);

  // Get all devices
  console.log('\n2️⃣  Getting all devices in group 57...');
  const { data: allDevices } = await client.get('/api/devices');
  const devicesInGroup57 = allDevices.filter((d) => d.groupId === 57);

  console.log(`   Found ${devicesInGroup57.length} devices:\n`);

  devicesInGroup57.forEach((d) => {
    console.log(`   📍 ${d.name}`);
    console.log(`      ID: ${d.id}`);
    console.log(`      IMEI: ${d.uniqueId}`);
    console.log(`      Status: ${d.status}`);
    console.log(`      Last Update: ${d.lastUpdate || 'N/A'}`);
    console.log();
  });

  // Check who else has access to group 57
  console.log('3️⃣  Checking who has access to group 57...');
  const { data: users } = await client.get('/api/users');

  console.log('   Checking each user...\n');

  let usersWithAccess = 0;
  for (const user of users) {
    // Skip admin
    if (user.administrator) continue;

    // Get groups for this user
    const { data: userGroups } = await client.get('/api/groups', {
      params: { userId: user.id },
    });

    const hasGroup57 = userGroups.some((g) => g.id === 57);
    if (hasGroup57) {
      console.log(`   ✅ ${user.name} (${user.email})`);
      usersWithAccess++;
    }
  }

  if (usersWithAccess === 0) {
    console.log('   (No non-admin users have access)');
  }

  console.log('\n═'.repeat(60));
}

main();
