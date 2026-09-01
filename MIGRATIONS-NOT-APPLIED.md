# ⚠️ Migrations Not Applied - Manual Steps Required

## สถานการถ์ตอนนี้

**ปัญหา:** Supabase ไม่อนุญาตให้ apply migrations ผ่าน API โดยตรง (security restriction)

**ผลกระทบ:**
- 🔴 Table `cl_payment_slots` ยังไม่มีใน database
- 🔴 Table `cl_payment_queue` ยังไม่มี
- 🔴 Functions ต่างๆ ยังไม่ได้สร้าง (reserve_payment_slot, etc.)
- 🔴 ระบบ Payment จะยังใช้งานไม่ได้

---

## ✅ วิธีแก้ (เลือก 1 วิธี)

### วิธีที่ 1: Supabase Dashboard (แนะนำ - ง่ายที่สุด)

**ขั้นตอน:**

1. **เปิด SQL Editor:**
   ```
   https://supabase.com/dashboard/project/zenfuxlykduaxrsnhmlq/sql/new
   ```

2. **Copy Migration 1 แล้ว Run:**
   ```bash
   cat supabase/migrations/20260830000000_payment_slots.sql
   ```
   - Copy ทั้งหมด → Paste ใน SQL Editor → Click "Run"
   - ควรเห็น: "Success. No rows returned"

3. **Copy Migration 2 แล้ว Run:**
   ```bash
   cat supabase/migrations/20260830000001_payment_queue.sql
   ```
   - Copy → Paste → Run

4. **Copy Migration 3 แล้ว Run:**
   ```bash
   cat supabase/migrations/20260830000002_slot_cleanup.sql
   ```
   - Copy → Paste → Run

5. **ตรวจสอบผลลัพธ์:**
   - ไปที่ Table Editor: https://supabase.com/dashboard/project/zenfuxlykduaxrsnhmlq/editor
   - ควรเห็น table ใหม่:
     - `cl_payment_slots` (99 rows)
     - `cl_payment_queue` (0 rows)
   - ไปที่ Database → Functions
   - ควรเห็น 5 functions ใหม่

**เวลา:** 5 นาที

---

### วิธีที่ 2: Install PostgreSQL แล้วใช้ psql

**ขั้นตอน:**

1. **Install PostgreSQL:**
   ```bash
   brew install postgresql@16
   ```

2. **Connect to Supabase:**
   ```bash
   psql "postgresql://postgres.zenfuxlykduaxrsnhmlq:Bellerox2026!@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres"
   ```

3. **Run Migrations:**
   ```sql
   \i supabase/migrations/20260830000000_payment_slots.sql
   \i supabase/migrations/20260830000001_payment_queue.sql
   \i supabase/migrations/20260830000002_slot_cleanup.sql
   \q
   ```

**เวลา:** 10 นาที (รวมการติดตั้ง)

---

### วิธีที่ 3: Supabase Management API (Advanced)

**ต้องการ:** Personal Access Token จาก https://supabase.com/dashboard/account/tokens

**ขั้นตอน:**
```bash
export SUPABASE_ACCESS_TOKEN="your-token-here"
./apply-migrations-mgmt.sh
```

**เวลา:** 3 นาที (ถ้ามี token แล้ว)

---

## 📋 Migration Files ที่ต้อง Apply

```
supabase/migrations/
├── 20260830000000_payment_slots.sql     ✅ พร้อม (Slot pool + reserve/release functions)
├── 20260830000001_payment_queue.sql     ✅ พร้อม (Queue system + processing)
└── 20260830000002_slot_cleanup.sql      ✅ พร้อม (Auto-cleanup expired reservations)
```

ไฟล์ทั้ง 3 ถูกสร้างและ commit แล้ว พร้อม apply

---

## 🔍 วิธีตรวจสอบว่า Apply สำเร็จ

### 1. ตรวจสอบ Tables
```sql
-- ควรได้ 99
SELECT COUNT(*) FROM cl_payment_slots;

-- ควรได้ 0 (ว่างตอนเริ่มต้น)
SELECT COUNT(*) FROM cl_payment_queue;
```

### 2. ตรวจสอบ Functions
```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%payment%'
ORDER BY routine_name;
```

**ควรเห็น 5 functions:**
- `add_to_payment_queue`
- `cleanup_expired_reservations`
- `process_payment_queue`
- `release_payment_slot`
- `reserve_payment_slot`

### 3. ทดสอบ Reserve Slot
```sql
SELECT reserve_payment_slot(210, '2026-09-01 10:00:00');
```

ควรได้ JSON:
```json
{
  "slot_number": 1,
  "tagged_amount": 210.01,
  "expires_at": "2026-09-01T10:15:00"
}
```

---

## ⏭️ หลังจาก Apply สำเร็จแล้ว

1. **ทดสอบในแอป:**
   ```bash
   cd bellerox-gps-web
   npm run dev
   ```

2. **ไปที่หน้า Billing:**
   ```
   http://localhost:3000/billing
   ```

3. **คลิก "ต่ออายุ" บนรถคันใดก็ได้:**
   - ควรเห็น QR Code
   - จำนวนเงินควร tag (เช่น ฿210.47)
   - ไม่มี error "table not found"

4. **ตรวจสอบ Network Tab:**
   - POST `/rest/v1/rpc/reserve_payment_slot` → สำเร็จ
   - Response: `{ slot_number: 1, tagged_amount: 210.01 }`

---

## 📝 Notes

- ⚠️ ต้อง apply ทั้ง 3 ไฟล์ตามลำดับ
- ⚠️ ถ้า apply ซ้ำจะมี error "already exists" (ปกติ ไม่ต้องกังวล)
- ⚠️ ถ้าต้องการ reset: DROP TABLE ก่อนแล้ว apply ใหม่

---

## 🆘 Troubleshooting

### "Function already exists"
→ ปกติ หมายถึว่า apply ไปแล้ว

### "Table already exists"
→ ปกติ หมายถึว่า apply ไปแล้ว

### "Permission denied"
→ ตรวจสอบว่าใช้ service_role key หรือ login เป็น project owner

### ทดสอบใน app แล้วยัง error
→ Hard refresh: Cmd+Shift+R (clear cache)
→ Check Network tab ว่า API call ไปที่ไหน

---

**สร้างเมื่อ:** 2026-08-31  
**Status:** Waiting for manual migration  
**Next:** Apply via Dashboard → Test in app
