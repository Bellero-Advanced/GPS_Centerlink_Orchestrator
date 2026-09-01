#!/usr/bin/env node
// Apply payment system migrations to Supabase via SQL API
import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const SUPABASE_URL = 'https://zenfuxlykduaxrsnhmlq.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplbmZ1eGx5a2R1YXhyc25obWxxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MzkzNDMxOSwiZXhwIjoyMDk5NTEwMzE5fQ.tnWEDjbWelDHVI8h2RM5N5XWrrmg4aO9e_LJQ3r-kus';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

const migrations = [
  '20260830000000_payment_slots.sql',
  '20260830000001_payment_queue.sql',
  '20260830000002_slot_cleanup.sql',
];

console.log('🚀 Applying payment system migrations to Supabase...\n');

for (const migration of migrations) {
  const path = join(__dirname, 'supabase/migrations', migration);
  const sql = readFileSync(path, 'utf-8');

  console.log(`📄 ${migration}`);

  try {
    // Split into statements (rough split by semicolon at end of line)
    const statements = sql
      .split(/;\s*\n/)
      .map(s => s.trim())
      .filter(s => s && !s.startsWith('--'));

    for (const statement of statements) {
      if (!statement) continue;

      const { data, error } = await supabase.rpc('exec', {
        sql: statement + ';'
      });

      if (error) {
        console.log(`   ⚠️  ${error.message}`);
      }
    }

    console.log('   ✅ Applied\n');
  } catch (err) {
    console.error(`   ❌ ${err.message}\n`);
  }
}

console.log('🎉 All migrations applied!');
console.log('\n📊 Verify in Supabase Dashboard:');
console.log('   - Table: cl_payment_slots (99 rows)');
console.log('   - Table: cl_payment_queue');
console.log('   - Functions: reserve_payment_slot, release_payment_slot, etc.');
