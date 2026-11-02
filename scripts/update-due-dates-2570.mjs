#!/usr/bin/env node
/**
 * Update all payment due dates for admin_gpsthailand to start in 2570 (2027)
 * Usage: SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node scripts/update-due-dates-2570.mjs
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: { persistSession: false }
});

async function main() {
  console.log('🔍 Fetching subscriptions for admin_gpsthailand...');

  const { data: subs, error: fetchError } = await supabase
    .from('billing_subscriptions')
    .select('id, tenant_id, device_id, vehicle_imei, end_date, status')
    .eq('tenant_id', 'admin_gpsthailand');

  if (fetchError) {
    console.error('❌ Failed to fetch subscriptions:', fetchError.message);
    process.exit(1);
  }

  console.log(`✅ Found ${subs.length} subscriptions\n`);

  const newStartDate = new Date('2027-01-01T00:00:00+07:00'); // 1 Jan 2570 (Thai BE)
  let updated = 0;
  let errors = 0;

  for (const sub of subs) {
    const oldEndDate = new Date(sub.end_date);
    const newEndDate = new Date(newStartDate);
    newEndDate.setMonth(newStartDate.getMonth() + 1); // +1 month billing cycle

    console.log(`📝 ${sub.vehicle_imei} (device ${sub.device_id})`);
    console.log(`   Old: ${oldEndDate.toISOString().split('T')[0]} → New: ${newEndDate.toISOString().split('T')[0]}`);

    const { error: updateError } = await supabase
      .from('billing_subscriptions')
      .update({ end_date: newEndDate.toISOString() })
      .eq('id', sub.id);

    if (updateError) {
      console.error(`   ❌ Error: ${updateError.message}`);
      errors++;
    } else {
      console.log(`   ✅ Updated`);
      updated++;
    }
  }

  console.log(`\n═══════════════════════════════════════`);
  console.log(`✅ Updated: ${updated}`);
  console.log(`❌ Errors:  ${errors}`);
  console.log(`═══════════════════════════════════════`);
}

main().catch(err => {
  console.error('❌ Fatal error:', err);
  process.exit(1);
});
