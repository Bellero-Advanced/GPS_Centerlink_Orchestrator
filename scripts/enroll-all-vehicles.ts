#!/usr/bin/env tsx
// ═══════════════════════════════════════════════════════
// Auto-Enroll All Vehicles — Bellerox GPS
// Creates billing subscriptions for all devices with IMEI
// Start date: 2026-09-15 (15 กันยายน 2569)
// ═══════════════════════════════════════════════════════

import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

// Node 20 WebSocket support
import ws from 'ws';
// @ts-ignore
globalThis.WebSocket = ws;

// ── Configuration ─────────────────────────────────────────

const TRACCAR_API_URL = process.env.TRACCAR_API_URL || 'https://gps.bellerox.com/api';
const TRACCAR_EMAIL = process.env.TRACCAR_ADMIN_EMAIL;
const TRACCAR_PASSWORD = process.env.TRACCAR_ADMIN_PASSWORD;

const SUPABASE_URL = process.env.SUPABASE_URL!;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const START_DATE = '2026-09-15'; // 15 กันยายน 2569
const END_DATE = '2027-03-15';   // 6 เดือนหลัง (15 มีนาคม 2570)
const DEFAULT_PLAN = 'pro';       // Pro plan (฿210/6 months)
const DEFAULT_TENANT = 'default'; // Default tenant ID
const MONTHLY_AMOUNT = 35;        // Pro plan: ฿35/month (฿210/6 months)

// ── Types ─────────────────────────────────────────────────

interface TraccarDevice {
  id: number;
  name: string;
  uniqueId: string; // IMEI
  status: string;
  disabled: boolean;
}

interface Subscription {
  tenant_id: string;
  device_id: number;
  vehicle_imei: string;
  plan: string;
  status: string;
  start_date: string;
  end_date: string;
  monthly_amount: number;
}

// ── Main ──────────────────────────────────────────────────

async function main() {
  console.log('🚀 Starting vehicle enrollment...\n');

  // Step 1: Authenticate with Traccar (Basic Auth)
  console.log('1️⃣ Authenticating with Traccar...');

  if (!TRACCAR_EMAIL || !TRACCAR_PASSWORD) {
    throw new Error('TRACCAR_ADMIN_EMAIL and TRACCAR_ADMIN_PASSWORD required');
  }

  const authHeader = 'Basic ' + Buffer.from(`${TRACCAR_EMAIL}:${TRACCAR_PASSWORD}`).toString('base64');

  // Test auth by fetching server info
  const testRes = await fetch(`${TRACCAR_API_URL}/server`, {
    headers: {
      'Authorization': authHeader,
      'Accept': 'application/json',
    },
  });

  if (!testRes.ok) {
    throw new Error(`Traccar auth failed: ${testRes.status} ${testRes.statusText}`);
  }

  console.log('✅ Authenticated\n');

  // Step 2: Fetch all devices
  console.log('2️⃣ Fetching devices from Traccar...');

  const devicesRes = await fetch(`${TRACCAR_API_URL}/devices`, {
    headers: {
      'Authorization': authHeader,
      'Accept': 'application/json',
    },
  });

  if (!devicesRes.ok) {
    throw new Error(`Failed to fetch devices: ${devicesRes.statusText}`);
  }

  const devices: TraccarDevice[] = await devicesRes.json();

  // Filter: only devices with IMEI
  const devicesWithIMEI = devices.filter((d) => d.uniqueId && d.uniqueId.length > 0);

  console.log(`✅ Found ${devices.length} total devices`);
  console.log(`   └─ ${devicesWithIMEI.length} with IMEI\n`);

  // Step 3: Connect to Supabase
  console.log('3️⃣ Connecting to Supabase...');

  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required');
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  console.log('✅ Connected\n');

  // Step 4: Check existing subscriptions
  console.log('4️⃣ Checking existing subscriptions...');

  const { data: existing, error: fetchError } = await supabase
    .from('billing_subscriptions')
    .select('device_id');

  if (fetchError) {
    throw new Error(`Failed to fetch existing: ${fetchError.message}`);
  }

  const existingIds = new Set(existing?.map((s) => s.device_id) || []);
  console.log(`✅ ${existingIds.size} subscriptions already exist\n`);

  // Step 5: Create new subscriptions
  console.log('5️⃣ Creating new subscriptions...');

  const newSubscriptions: Subscription[] = [];

  for (const device of devicesWithIMEI) {
    if (existingIds.has(device.id)) {
      console.log(`   ⏭️  Skipping ${device.name} (already enrolled)`);
      continue;
    }

    newSubscriptions.push({
      tenant_id: DEFAULT_TENANT,
      device_id: device.id,
      vehicle_imei: device.uniqueId,
      plan: DEFAULT_PLAN,
      status: 'active',
      start_date: START_DATE,
      end_date: END_DATE,
      monthly_amount: MONTHLY_AMOUNT,
    });
  }

  console.log(`\n📋 ${newSubscriptions.length} new subscriptions to create\n`);

  if (newSubscriptions.length === 0) {
    console.log('✅ All vehicles already enrolled!\n');
    return;
  }

  // Insert in batches (500 at a time)
  const BATCH_SIZE = 500;
  let created = 0;

  for (let i = 0; i < newSubscriptions.length; i += BATCH_SIZE) {
    const batch = newSubscriptions.slice(i, i + BATCH_SIZE);

    const { error: insertError } = await supabase
      .from('billing_subscriptions')
      .insert(batch);

    if (insertError) {
      console.error(`❌ Batch ${Math.floor(i / BATCH_SIZE) + 1} failed:`, insertError.message);
      continue;
    }

    created += batch.length;
    console.log(`   ✅ Created ${created}/${newSubscriptions.length}`);
  }

  console.log(`\n🎉 Enrollment complete!\n`);
  console.log('📊 Summary:');
  console.log(`   • Total devices: ${devices.length}`);
  console.log(`   • Devices with IMEI: ${devicesWithIMEI.length}`);
  console.log(`   • Already enrolled: ${existingIds.size}`);
  console.log(`   • Newly enrolled: ${created}`);
  console.log(`   • Start date: ${START_DATE}`);
  console.log(`   • End date: ${END_DATE}`);
  console.log(`   • Plan: ${DEFAULT_PLAN}\n`);
}

// ── Run ───────────────────────────────────────────────────

main().catch((err) => {
  console.error('\n❌ Error:', err.message);
  process.exit(1);
});
