# 🚀 Apply Payment Migrations to Supabase

## ⚠️ Automatic Migration Failed

Supabase REST API ไม่มี `exec_sql` function (security restriction)

## ✅ Manual Steps (ต้องทำเองใน Supabase Dashboard)

### 1. เปิด Supabase SQL Editor
```
https://supabase.com/dashboard/project/zenfuxlykduaxrsnhmlq/sql/new
```

### 2. Run Migration 1: Payment Slots
Copy + Paste + Run ไฟล์นี้:
```bash
cat supabase/migrations/20260830000000_payment_slots.sql
```

**Expected Result:**
- ✅ Table `cl_payment_slots` created
- ✅ 99 rows inserted (slot_number 1-99)
- ✅ Functions: `reserve_payment_slot`, `release_payment_slot`

### 3. Run Migration 2: Payment Queue
```bash
cat supabase/migrations/20260830000001_payment_queue.sql
```

**Expected Result:**
- ✅ Table `cl_payment_queue` created
- ✅ Functions: `add_to_payment_queue`, `process_payment_queue`

### 4. Run Migration 3: Slot Cleanup
```bash
cat supabase/migrations/20260830000002_slot_cleanup.sql
```

**Expected Result:**
- ✅ Function `cleanup_expired_reservations` created
- ✅ Trigger scheduled (every 1 minute)

---

## 🔍 Verify After Running

### Check Tables
```sql
-- Should return 99 rows
SELECT COUNT(*) FROM cl_payment_slots;

-- Should return 0 rows (empty queue initially)
SELECT COUNT(*) FROM cl_payment_queue;
```

### Check Functions
```sql
-- List all functions
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%payment%'
ORDER BY routine_name;
```

**Expected Output:**
- `add_to_payment_queue` (function)
- `cleanup_expired_reservations` (function)
- `process_payment_queue` (function)
- `release_payment_slot` (function)
- `reserve_payment_slot` (function)

---

## 🎯 Alternative: Use Supabase CLI (Recommended)

### Install Supabase CLI
```bash
brew install supabase/tap/supabase
```

### Link to Project
```bash
supabase link --project-ref zenfuxlykduaxrsnhmlq
# Paste service_role key when prompted
```

### Push Migrations
```bash
supabase db push
```

This will automatically apply all migrations in `supabase/migrations/`.

---

## 📝 Migration Files Location
```
supabase/migrations/
├── 20260830000000_payment_slots.sql     (Slot pool + functions)
├── 20260830000001_payment_queue.sql     (Queue system)
└── 20260830000002_slot_cleanup.sql      (Auto-cleanup)
```

---

## ✅ After Migration Complete

1. **Verify in Dashboard:**
   - Tables: `cl_payment_slots` (99 rows), `cl_payment_queue` (0 rows)
   - Functions: 5 functions created

2. **Test in App:**
   ```bash
   cd bellerox-gps-web
   npm run dev
   ```
   - Go to `/billing`
   - Click "ต่ออายุ" on any vehicle
   - Should see QR with tagged amount (฿210.01-210.99)

3. **Test Slot Reservation:**
   - Open browser DevTools > Network
   - Click "ต่ออายุ"
   - Should see POST to `/rest/v1/rpc/reserve_payment_slot`
   - Response: `{ slot_number: 1, tagged_amount: 210.01 }`

---

## 🆘 Troubleshooting

### "Function not found"
- Run migrations in order (1 → 2 → 3)
- Check SQL Editor for error messages

### "Table already exists"
- Drop tables first:
  ```sql
  DROP TABLE IF EXISTS cl_payment_queue CASCADE;
  DROP TABLE IF EXISTS cl_payment_slots CASCADE;
  ```
- Then re-run migrations

### "Permission denied"
- Make sure you're logged in as project owner
- Use service_role key (not anon key)
