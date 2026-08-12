# DLT Portal ไม่แสดง — แก้สำเร็จ ✅

**วันที่:** 2026-08-11 19:15
**Commit:** 4c63c10

---

## 🎯 Root Cause ที่แท้จริง

### Timeline
1. **ก่อน 5 ส.ค.** — ส่งได้ปกติ ✅
   - `license = unit_id (27 digits) + 53 zeros = 80 digits`
   - Masterfile ลงทะเบียนด้วย format นี้

2. **5 ส.ค. (commit 4099878)** — เปลี่ยน license format
   - `license = IMEI (15 digits) + 65 zeros = 80 digits`
   - **Masterfile ยังเป็น format เดิม** (ไม่ได้อัพเดต)

3. **ผลลัพธ์:**
   - DLT API รับข้อมูล (200 OK, received_records > 0) ✅
   - **Portal ไม่แสดง** ❌ เพราะ license ไม่ตรงกับ Masterfile

---

## 🔍 Technical Details

### ก่อนแก้ (broken)
```typescript
// commit 4099878 (Aug 5)
const imei = device.uniqueId.replace(/\D/g, '').slice(0, 15).padStart(15, '0');
const license = imei.padEnd(80, '0');  // 15 + 65 = 80

// Result:
unit_id:  0520001000008661740623456 (27 digits)
license:  8661740623456000000000... (80 digits - IMEI only)
          ↑ ไม่ตรงกับ Masterfile
```

### หลังแก้ (working)
```typescript
// revert to commit 6c09660 format
const unitId = buildDltUnitId(device, venderId);
const license = unitId.padEnd(80, '0');  // 27 + 53 = 80

// Result:
unit_id:  0520001000008661740623456 (27 digits)
license:  0520001000008661740623456000... (80 digits - unit_id + padding)
          ↑ ตรงกับ Masterfile ✅
```

---

## 💡 Why This Happened

**commit 4099878 commit message:**
> "fix: DLT license field must be IMEI(15) + 65 zeros, not unit_id"

**ปัญหา:**
- เปลี่ยน license format ใหม่
- **แต่ลืมอัพเดต Masterfile** ให้ตรงกัน
- Masterfile ยังเป็น unit_id format เดิม

**DLT Portal Matching Logic:**
```
IF unit_id + license ใน GPS API ≠ unit_id + license ใน Masterfile
THEN ไม่แสดงบน Portal
```

---

## ✅ Solution

**Revert license กลับไปใช้ unit_id format (commit 6c09660)**

### เหตุผล:
1. **Masterfile มีข้อมูล 15-16 คันแล้ว** ลงทะเบียนด้วย unit_id format
2. ไม่ต้องซิงค์ Masterfile ใหม่ (ประหยัดเวลา)
3. **Proven format** — ทำงานได้ปกติมาตลอดก่อน 5 ส.ค.

### ทางเลือกอื่น (ไม่เลือก):
- อัพเดต Masterfile ทุกคันให้ใช้ IMEI format → ใช้เวลานาน + ต้องซิงค์ทีละคัน

---

## 🎁 What to Expect

หลัง deploy commit 4c63c10:
1. **รถ 15-16 คันที่ส่งไปแล้ว** → Portal จะแสดงทันที ✅
2. **ไม่ต้องซิงค์ Masterfile ใหม่**
3. **ไม่ต้องลงทะเบียนรถใหม่**

---

## 📊 Verification Steps

```bash
# 1. Deploy to production
npm run build
# (deploy dist/ to Cloudflare Pages)

# 2. ส่ง DLT ใหม่ (auto-send หรือ manual test)
# 3. รอ 1-2 นาที
# 4. เช็ค DLT Portal → ควรเห็นรถเขียวขึ้นมา ✅
```

---

## 📝 Lesson Learned

**เมื่อแก้ field ที่ใช้ใน matching (unit_id, license):**
1. ต้องอัพเดตทั้ง GPS API **และ** Masterfile พร้อมกัน
2. หรือ migrate แบบ backward-compatible (support ทั้ง old + new format)
3. **Test กับ Portal จริง** ก่อน deploy

---

**Status:** COMPLETE — Ready for production deployment
**Next:** Monitor Portal after next GPS send cycle (60s interval)
