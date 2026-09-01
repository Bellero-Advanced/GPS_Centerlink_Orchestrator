#!/usr/bin/env node
/**
 * Apply Payment System Migrations to Supabase
 * Uses service_role key to execute SQL directly
 */

import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const SUPABASE_URL = 'https://zenfuxlykduaxrsnhmlq.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplbmZ1eGx5a2R1YXhyc25obWxxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MzkzNDMxOSwiZXhwIjoyMDk5NTEwMzE5fQ.tnWEDjbWelDHVI8h2RM5N5XWrrmg4aO9e_LJQ3r-kus';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

const migrations = [
  '20260830000000_payment_slots.sql',
  '20260830000001_payment_queue.sql',
  '20260830000002_slot_cleanup.sql',
];

console.log('🚀 Applying Payment System Migrations to Supabase\n');
console.log('Project: zenfuxlykduaxrsnhmlq');
console.log('URL: https://zenfuxlykduaxrsnhmlq.supabase.co\n');

let successCount = 0;
let errorCount = 0;

for (const migration of migrations) {
  const path = join(__dirname, 'supabase/migrations', migration);
  const sql = readFileSync(path, 'utf-8');

  console.log(`📄 ${migration}`);

  try {
    // Execute raw SQL via REST API
    const { data, error } = await supabase.rpc('exec', { sql });

    if (error) {
      // Try direct query if exec RPC doesn't exist
      const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/query`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query: sql }),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${await response.text()}`);
      }

      console.log('   ✅ Applied\n');
      successCount++;
    } else {
      console.log('   ✅ Applied\n');
      successCount++;
    }
  } catch (err) {
    console.error(`   ❌ Error: ${err.message}\n`);
    errorCount++;
  }
}

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log(`✅ Success: ${successCount} / ${migrations.length}`);
console.log(`❌ Errors: ${errorCount} / ${migrations.length}`);

if (errorCount > 0) {
  console.log('\n⚠️  Some migrations failed. Please apply manually via Supabase Dashboard:');
  console.log('   https://supabase.com/dashboard/project/zenfuxlykduaxrsnhmlq/sql/new');
  process.exit(1);
} else {
  console.log('\n🎉 All migrations applied successfully!');
  console.log('\n📊 Verify in Supabase Dashboard:');
  console.log('   - Table: cl_payment_slots (should have 99 rows)');
  console.log('   - Table: cl_payment_queue');
  console.log('   - Functions: reserve_payment_slot, release_payment_slot, etc.');
}
