#!/usr/bin/env node
/**
 * Apply Payment System Migrations to Supabase
 * Uses direct fetch API (no Supabase client dependency)
 */

import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const SUPABASE_URL = 'https://zenfuxlykduaxrsnhmlq.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplbmZ1eGx5a2R1YXhyc25obWxxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MzkzNDMxOSwiZXhwIjoyMDk5NTEwMzE5fQ.tnWEDjbWelDHVI8h2RM5N5XWrrmg4aO9e_LJQ3r-kus';

const migrations = [
  '20260830000000_payment_slots.sql',
  '20260830000001_payment_queue.sql',
  '20260830000002_slot_cleanup.sql',
];

console.log('🚀 Applying Payment System Migrations to Supabase\n');
console.log('Project: zenfuxlykduaxrsnhmlq');
console.log('URL: https://zenfuxlykduaxrsnhmlq.supabase.co\n');

let successCount = 0;
let failedMigrations = [];

for (const migration of migrations) {
  const path = join(__dirname, 'supabase/migrations', migration);
  const sql = readFileSync(path, 'utf-8');

  console.log(`📄 ${migration}`);

  try {
    // Split SQL into individual statements
    const statements = sql
      .split(/;\s*\n/)
      .map(s => s.trim())
      .filter(s => s && !s.startsWith('--') && s.length > 10);

    let stmtCount = 0;
    for (const statement of statements) {
      // Execute via PostgREST query endpoint
      const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: JSON.stringify({ query: statement + ';' }),
      });

      if (!response.ok) {
        const errorText = await response.text();

        // If exec RPC doesn't exist, try alternative approach
        if (errorText.includes('function public.exec') || errorText.includes('does not exist')) {
          console.log('   ⚠️  Cannot apply via API (exec function missing)');
          failedMigrations.push(migration);
          break;
        }

        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      stmtCount++;
    }

    if (!failedMigrations.includes(migration)) {
      console.log(`   ✅ Applied (${stmtCount} statements)\n`);
      successCount++;
    } else {
      console.log('');
    }
  } catch (err) {
    console.error(`   ❌ Error: ${err.message}\n`);
    failedMigrations.push(migration);
  }
}

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log(`✅ Success: ${successCount} / ${migrations.length}`);
console.log(`❌ Failed: ${failedMigrations.length} / ${migrations.length}`);

if (failedMigrations.length > 0) {
  console.log('\n⚠️  API migration not available. Use manual method:\n');
  console.log('OPTION 1: Supabase Dashboard (Recommended)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('1. Open: https://supabase.com/dashboard/project/zenfuxlykduaxrsnhmlq/sql/new');
  console.log('2. Copy SQL from each migration file:');
  failedMigrations.forEach(m => {
    console.log(`   - supabase/migrations/${m}`);
  });
  console.log('3. Paste into SQL Editor');
  console.log('4. Click "Run"\n');

  console.log('OPTION 2: psql Command Line');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('psql "postgresql://postgres.zenfuxlykduaxrsnhmlq:[PASSWORD]@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres"');
  console.log('\\i supabase/migrations/20260830000000_payment_slots.sql');
  console.log('\\i supabase/migrations/20260830000001_payment_queue.sql');
  console.log('\\i supabase/migrations/20260830000002_slot_cleanup.sql\n');

  process.exit(1);
} else {
  console.log('\n🎉 All migrations applied successfully!');
  console.log('\n📊 Verify in Supabase Dashboard:');
  console.log('   https://supabase.com/dashboard/project/zenfuxlykduaxrsnhmlq');
  console.log('   - Table Editor: cl_payment_slots (should have 99 rows)');
  console.log('   - Table Editor: cl_payment_queue');
  console.log('   - Database > Functions: 5 payment functions');
}
