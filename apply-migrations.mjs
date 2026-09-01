#!/usr/bin/env node
// Apply payment system migrations to Supabase via Management API
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const SUPABASE_URL = 'https://zenfuxlykduaxrsnhmlq.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplbmZ1eGx5a2R1YXhyc25obWxxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MzkzNDMxOSwiZXhwIjoyMDk5NTEwMzE5fQ.tnWEDjbWelDHVI8h2RM5N5XWrrmg4aO9e_LJQ3r-kus';

const migrations = [
  '20260830000000_payment_slots.sql',
  '20260830000001_payment_queue.sql',
  '20260830000002_slot_cleanup.sql',
];

console.log('🚀 Applying payment system migrations...\n');

for (const migration of migrations) {
  const path = join(__dirname, 'supabase/migrations', migration);
  const sql = readFileSync(path, 'utf-8');

  console.log(`📄 Applying: ${migration}`);

  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query: sql }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.log(`   ⚠️  ${error}`);
    } else {
      console.log('   ✅ Applied\n');
    }
  } catch (err) {
    console.error(`   ❌ Error: ${err.message}\n`);
  }
}

console.log('🎉 Migration process complete!');
