#!/usr/bin/env node
// Debug Traccar Permissions — ตรวจสอบว่าทำไม user tnr ไม่เห็นรถ 84-9318

import axios from '../bellerox-gps-web/node_modules/axios/index.js';

// ใช้ Cloudflare Worker API แทน (nginx บล็อก direct access)
const TRACCAR_URL = 'https://api.centerlink.co.th';

// Helper: Login และ return axios client with Basic Auth
async function loginTraccar(email, password) {
  const auth = Buffer.from(`${email}:${password}`).toString('base64');
  const client = axios.create({
    baseURL: TRACCAR_URL,
    headers: {
      Authorization: `Basic ${auth}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    withCredentials: false, // ตาม traccarClient.ts
  });

  // Verify login by calling /api/devices (safer than /api/session)
  try {
    const { data: devices } = await client.get('/api/devices');
    console.log(`✅ Logged in as: ${email} — can see ${devices.length} devices`);

    // Get user info
    const { data: users } = await client.get('/api/users');
    const user = users.find(u => u.email === email);

    return { client, user, devices };
  } catch (err) {
    console.error(`❌ Login failed:`, err.response?.data || err.message);
    process.exit(1);
  }
}

async function main() {
  console.log('🔍 Traccar Permission Debugger\n');
  console.log('═'.repeat(60));

  // Step 1: Login as admin
  console.log('\n1️⃣  Login as admin_gpsthailand...');
  const admin = await loginTraccar('admin_gpsthailand', 'admin123');
  const allDevices = admin.devices;

  console.log(`   User info: ${admin.user?.name} (Admin: ${admin.user?.administrator})`);

  // Step 2: Find device 84-9318 (uniqueId: 153230617901)
  console.log('\n2️⃣  Finding device 84-9318 (IMEI: 153230617901)...');
  const device = allDevices.find(
    (d) => d.name === '84-9318' || d.uniqueId === '153230617901'
  );

  if (!device) {
    console.error('❌ Device not found in Traccar!');
    console.log('Available devices:', allDevices.slice(0, 10).map((d) => `${d.name} (${d.uniqueId})`));
    process.exit(1);
  }

  console.log(`✅ Found device: ${device.name} (ID: ${device.id}, IMEI: ${device.uniqueId})`);
  console.log(`   Group ID: ${device.groupId || 'None'}`);

  // Step 3: Find group "ห้างหุ้นส่วนจำกัด ธรณินทร์ ดิน น้ำ ลม ไฟ"
  console.log('\n3️⃣  Finding group "ห้างหุ้นส่วนจำกัด ธรณินทร์ ดิน น้ำ ลม ไฟ"...');
  const { data: groups } = await admin.client.get('/api/groups');
  const targetGroup = groups.find((g) =>
    g.name.includes('ธรณินทร์') || g.name.includes('ดิน') || g.name.includes('น้ำ')
  );

  if (!targetGroup) {
    console.error('❌ Group not found!');
    console.log('Available groups:', groups.map((g) => `${g.name} (ID: ${g.id})`));
  } else {
    console.log(`✅ Found group: ${targetGroup.name} (ID: ${targetGroup.id})`);

    if (device.groupId !== targetGroup.id) {
      console.warn(`⚠️  Device is in group ${device.groupId}, NOT ${targetGroup.id}!`);
    }
  }

  // Step 4: Find user "tnr" or "trn"
  console.log('\n4️⃣  Finding user "tnr" or "trn"...');
  const { data: users } = await admin.client.get('/api/users');

  // ลองหา tnr ก่อน (ตามที่พี่โตพิมพ์มา)
  let targetUser = users.find((u) => u.email === 'tnr' || u.name === 'tnr');

  if (!targetUser) {
    console.log('⚠️  User "tnr" not found. Checking "trn" and "TRN"...');

    // หา trn (ตัวเล็ก)
    const trnLower = users.find((u) => u.email === 'trn' || u.name.includes('(trn)'));
    // หา TRN (ตัวใหญ่)
    const trnUpper = users.find((u) => u.email === 'TRN' || u.name.includes('(TRN)'));

    console.log(`   Found TRN (uppercase): ${trnUpper ? trnUpper.name + ' (' + trnUpper.email + ')' : 'NOT FOUND'}`);
    console.log(`   Found trn (lowercase): ${trnLower ? trnLower.name + ' (' + trnLower.email + ')' : 'NOT FOUND'}`);

    // ใช้ตัวที่เจอตัวแรก
    targetUser = trnUpper || trnLower;

    if (!targetUser) {
      console.error('\n❌ None of "tnr", "trn", or "TRN" found!');
      console.log('\n💡 Hint: Did you mean one of these?');
      users.filter(u => u.name.includes('ธรณินทร์')).forEach(u =>
        console.log(`   - ${u.name} (email: ${u.email})`)
      );
      process.exit(1);
    }

    console.log(`\n   → Using: ${targetUser.name} (email: ${targetUser.email})`);
  }

  console.log(`✅ Found user: ${targetUser.name} (ID: ${targetUser.id}, Email: ${targetUser.email})`);

  // Step 5: Check what devices targetUser can see
  console.log('\n5️⃣  Checking what devices this user can see...');
  const { data: userDevices } = await admin.client.get('/api/devices', {
    params: { userId: targetUser.id },
  });

  console.log(`   User can see ${userDevices.length} devices:`);
  userDevices.slice(0, 10).forEach((d) => console.log(`   - ${d.name} (ID: ${d.id})`));
  if (userDevices.length > 10) console.log(`   ... and ${userDevices.length - 10} more`);

  const canSeeCar = userDevices.some((d) => d.id === device.id);
  if (canSeeCar) {
    console.log(`\n✅ User CAN see device ${device.name}!`);
  } else {
    console.log(`\n❌ User CANNOT see device ${device.name}!`);
  }

  // Step 6: Check what groups targetUser can see
  console.log('\n6️⃣  Checking what groups this user can see...');
  const { data: userGroups } = await admin.client.get('/api/groups', {
    params: { userId: targetUser.id },
  });

  console.log(`   User can see ${userGroups.length} groups:`);
  userGroups.forEach((g) => console.log(`   - ${g.name} (ID: ${g.id})`));

  if (targetGroup) {
    const canSeeGroup = userGroups.some((g) => g.id === targetGroup.id);
    if (canSeeGroup) {
      console.log(`\n✅ User CAN see group "${targetGroup.name}"!`);
    } else {
      console.log(`\n❌ User CANNOT see group "${targetGroup.name}"!`);
    }
  }

  // Step 7: Diagnosis
  console.log('\n' + '═'.repeat(60));
  console.log('📋 DIAGNOSIS:\n');

  if (!canSeeCar) {
    console.log(`❌ Problem: User "${targetUser.name}" does not have permission to see device 84-9318.\n`);
    console.log('💡 Solution: You need to link the permission. Choose ONE:');
    console.log('');
    console.log('   Option A: Grant access to the DEVICE directly');
    console.log(`   POST /api/permissions`);
    console.log(`   Body: { "userId": ${targetUser.id}, "deviceId": ${device.id} }`);
    console.log('');

    if (targetGroup && device.groupId === targetGroup.id) {
      console.log('   Option B: Grant access to the GROUP (recommended if multiple devices)');
      console.log(`   POST /api/permissions`);
      console.log(`   Body: { "userId": ${targetUser.id}, "groupId": ${targetGroup.id} }`);
      console.log('');
    } else if (targetGroup) {
      console.log(`   ⚠️  NOTE: Device is in group "${device.groupId}" but target group is "${targetGroup.id}"`);
      console.log(`   You may need to MOVE the device to the correct group first!`);
      console.log('');
    }

    console.log('Would you like me to fix this automatically? [y/N]');
  } else {
    console.log(`✅ User "${targetUser.name}" already has permission! The issue is somewhere else.`);
    console.log('');
    console.log('Check:');
    console.log('1. Is the web app using the correct login credentials?');
    console.log('2. Is there a frontend filter hiding this device?');
    console.log(`3. Try logging in as ${targetUser.email} via Traccar UI to verify: https://gps.centerlink.co.th/app`);
  }

  console.log('═'.repeat(60));
}

main();
