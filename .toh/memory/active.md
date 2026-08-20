---
updated: 2026-08-20
---

# Active Work

## ✅ Completed: Reports Fix + IMEI Edit System

**Date:** 2026-08-20

### What was done:

**Reports System:**
- ✅ ลบ monthly report tab จาก `ReportsPageUnified.tsx`
- ✅ ลบ import `MonthlySummaryReport` และ `BarChart2` icon
- ✅ เปลี่ยน subtitle จาก "รายวัน · ย้อนหลัง · รายเดือน" เป็น "รายวัน · ย้อนหลัง"
- ✅ ตรวจสอบว่า metrics คำนวณถูกต้อง - `useDailyTripReport` ใช้ dateRange filter อยู่แล้ว

**IMEI Edit System:**
- ✅ ปลดล็อค IMEI field ใน `VehicleFormModal.tsx` (ลบ `readOnly={mode === 'edit'}`)
- ✅ เพิ่ม warning message "⚠️ การเปลี่ยน IMEI จะถูกบันทึกประวัติ"
- ✅ แก้ IMEI history tracking ใช้ `user?.email ?? 'unknown'` แทน `'current-user'`
- ✅ เพิ่ม import `useAuthStore` ใน VehicleFormModal
- ✅ แก้ปุ่ม "ประวัติ IMEI" ใน FleetPage ให้แสดงเสมอ (ไม่ซ่อนเมื่อ history ว่าง)

### Testing:
- ✅ `npm run build` — passed in 13.35s
- ✅ `npm run lint` — 42 warnings (pre-existing, acceptable)

### Deployment:
- Commit: `3413333`
- CI/CD: 🔄 Running (Build #32342398057)
- Expected: Deploy to https://gpsthailand.centerlink.co.th/ within 2-3 minutes

### Files changed:
- `src/pages/ReportsPageUnified.tsx` — ลบ monthly tab
- `src/components/fleet/VehicleFormModal.tsx` — ปลดล็อค IMEI + แก้ changedBy
- `src/pages/FleetPage.tsx` — แสดงปุ่ม IMEI History เสมอ

## Next: (awaiting user testing)

User should test:
1. เปิด `/app/reports` → ควรเห็นแค่ 2 tabs: "รายงานรายวัน" + "ย้อนหลัง"
2. เปิด `/app/fleet` → แก้ไขพาหนะ → ช่อง IMEI ควรแก้ไขได้
3. แก้ IMEI → บันทึก → คลิก action menu → "ประวัติ IMEI" → ควรเห็น log การเปลี่ยนแปลง
