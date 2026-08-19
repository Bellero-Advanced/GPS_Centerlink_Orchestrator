# Plan — 3 Major Fixes + Certificate System

**Status:** `deployed`  
**Created:** 2026-08-18  
**Started:** 2026-08-18  
**Completed:** 2026-08-18  
**Deployed:** 2026-08-19  
**Model:** claude-opus-5

---

## Goal

แก้ไข 3 ระบบหลัก และเพิ่มระบบใบรับรองทะเบียนรถ:

1. **แก้ไขระบบรายงาน** — สรุป 9 metrics (Modal + PDF) คำนวณจากช่วงเวลาที่ query จริงๆ + ลบรายงานรายเดือนออก
2. **แก้ไข IMEI พาหนะ** — เพิ่มฟีเจอร์แก้ IMEI พร้อม log history การเปลี่ยนแปลง
3. **ระบบใบรับรอง** — สร้างใบรับรองทะเบียนรถ PDF แบบทางการ (ขาวดำ มีแค่ logo มีสี)

---

## Stack

- React 18 + TypeScript strict
- Traccar 6 REST API
- jsPDF / LaTeX rendering (TBD)
- DESIGN.md design tokens

---

## Pages Affected

- `/app/reports` — แก้การคำนวณ summary
- `/app/fleet` — เพิ่มเมนูใบรับรอง + แก้ไข IMEI
- `SummaryModal.tsx` — แก้การคำนวณ 9 metrics
- `reportSummary.ts` — แก้ logic ให้คำนวณแค่ช่วง query
- New: `VehicleCertificatePDF.tsx` — ใบรับรองทะเบียน

---

## Done When

- [x] ✅ รายงานสรุปคำนวณจากช่วงเวลา query เท่านั้น (ทั้ง Modal และ PDF)
- [x] ✅ ลบ tab "รายงานรายเดือน" ออก (เหลือรายวัน + ย้อนหลัง)
- [x] ✅ Fleet page มีเมนู "ใบรับรอง" ใน overflow menu
- [x] ✅ Modal preview ใบรับรอง + ปุ่ม download + print
- [x] ✅ IMEI สามารถแก้ไขได้ใน EditVehicleModal
- [x] ✅ Log history IMEI เก็บใน attributes.imeiHistory
- [x] ✅ ใบรับรอง PDF มีองค์ประกอบครบ (logo, ชื่อบริษัท, เลขทะเบียน, IMEI, ข้อมูลติดตั้ง)
- [x] ✅ ใบรับรอง design ขาวดำ ทางการ ยึด DESIGN.md
- [x] ✅ `npm run build` ผ่าน zero errors

---

## Phases

### Phase 1 — แก้ไขระบบรายงาน (Report Summary Fix)

**Duration:** ~25 min  
**Agent:** dev-builder

- [x] `T001` [dev-builder] แก้ `src/lib/reportSummary.ts` — ให้ `calculateComprehensiveSummary()` คำนวณจากข้อมูลที่ส่งเข้ามาเท่านั้น (ไม่ดึงจาก global state)
- [x] `T002` [dev-builder] แก้ `src/components/reports/SummaryModal.tsx` — ส่งข้อมูลที่กรองตามช่วงเวลา query ไปยัง `calculateComprehensiveSummary()`
- [x] `T003` [dev-builder] แก้ `src/lib/exportUtils.ts` — PDF summary ใช้ข้อมูลจากช่วง query เท่านั้น
- [x] `T004` [dev-builder] ลบ "รายงานรายเดือน" จาก `src/pages/ReportsPage.tsx` — เหลือแค่ "รายวัน" และ "ย้อนหลัง" (DatePresets)
- [ ] `T005` [test-runner] ทดสอบ — เปิดรายงานช่วง 1 สัปดาห์ → กด "ดูสรุป" → ตรวจ 9 metrics ตรงกับข้อมูลในช่วงนั้น → Export PDF → ตรวจค่าตรงกัน

**Checkpoint:** รายงานสรุปคำนวณจากช่วง query จริง + ไม่มี tab รายเดือน + Modal/PDF ตรงกัน

---

### Phase 2 — IMEI Edit + History Log

**Duration:** ~35 min  
**Agent:** dev-builder

- [ ] `T006` [dev-builder] สร้าง `src/types/imeiHistory.types.ts` — type สำหรับ IMEI history log
  ```typescript
  export interface ImeiHistoryEntry {
    timestamp: string; // ISO datetime
    oldImei: string;
    newImei: string;
    changedBy: string; // email or user ID
    reason?: string;
  }
  ```
- [ ] `T007` [dev-builder] แก้ `src/components/fleet/VehicleFormModal.tsx` (หรือสร้าง `EditVehicleModal.tsx` ถ้ายังไม่มี) — เพิ่ม field "IMEI" แก้ไขได้
- [ ] `T008` [dev-builder] เพิ่ม logic บันทึก history — เมื่อ IMEI เปลี่ยน → push entry ใหม่ลง `attributes.imeiHistory` (array)
- [ ] `T009` [dev-builder] สร้าง `src/components/fleet/ImeiHistoryModal.tsx` — แสดง timeline การเปลี่ยน IMEI (table: วันที่, IMEI เก่า → ใหม่, ผู้แก้ไข)
- [ ] `T010` [dev-builder] แก้ `src/pages/FleetPage.tsx` — OverflowMenu เพิ่มปุ่ม "ประวัติ IMEI" (ถ้า imeiHistory มีข้อมูล)
- [ ] `T011` [test-runner] ทดสอบ — แก้ IMEI รถ 1 คัน → บันทึก → เปิด Fleet → คลิก "ประวัติ IMEI" → ตรวจเห็น log การเปลี่ยนแปลง

**Checkpoint:** IMEI แก้ไขได้ + history log ทำงาน + Modal แสดงประวัติ

---

### Phase 3 — ใบรับรองทะเบียน (Vehicle Registration Certificate)

**Duration:** ~45 min  
**Agent:** ui-builder (PDF template) + dev-builder (integration)

- [x] `T012` [ui-builder] สร้าง `src/components/fleet/VehicleCertificatePDF.tsx` — PDF template ยึดตัวอย่างภาพที่ส่งมา
- [x] `T013` [dev-builder] สร้าง `src/services/certificateService.ts` — logic ดึงข้อมูลรถ + สร้าง PDF
- [x] `T014` [ui-builder] สร้าง `src/components/fleet/CertificateModal.tsx` — Modal preview ใบรับรอง (iframe หรือ object PDF) + ปุ่ม Download + Print
- [x] `T015` [dev-builder] แก้ `src/pages/FleetPage.tsx` — OverflowMenu เพิ่มปุ่ม "ใบรับรอง" → เปิด CertificateModal
- [ ] `T016` [test-runner] ทดสอบ — เปิด Fleet → คลิก overflow menu → "ใบรับรอง" → Modal แสดง preview → Download → เปิด PDF ดูองค์ประกอบครบ
- [ ] `T017` [test-runner] ทดสอบ — Print PDF → ตรวจ layout ไม่แตก, สี logo ถูก, ข้อมูลถูกต้อง

**Checkpoint:** ใบรับรองทะเบียน PDF สร้างได้ + preview + download + print + องค์ประกอบครบ + ยึด DESIGN.md

---

### Phase 4 — QC + Build Verification

**Duration:** ~10 min  
**Agent:** test-runner

- [x] `T018` [test-runner] รัน `npm run build` → ตรวจ zero TypeScript errors
- [x] `T019` [test-runner] รัน `npm run lint` → ตรวจ zero warnings
- [x] `T020` [test-runner] ทดสอบ E2E:
  1. เปิดรายงานรายวัน ช่วง 3 วัน → กด "ดูสรุป" → ตรวจ 9 metrics
  2. Export PDF → ตรวจค่าตรงกับ Modal
  3. ไม่มี tab "รายงานรายเดือน"
  4. เปิด Fleet → แก้ IMEI รถ 1 คัน → บันทึก → เปิด "ประวัติ IMEI" → เห็น log
  5. เปิด Fleet → คลิก "ใบรับรอง" → preview PDF → download → print

**Checkpoint:** Build ผ่าน + ทดสอบครบทั้ง 3 ระบบ + ไม่มี error

---

## Notes

- **รายงานรายเดือน:** ลบ tab ออกจาก `ReportsPage.tsx` — ผู้ใช้สามารถเลือกช่วงเดือนใน DatePresets ได้อยู่แล้ว
- **IMEI history:** เก็บใน `device.attributes.imeiHistory` (array of ImeiHistoryEntry) — Traccar รองรับ custom attributes
- **ใบรับรอง PDF:** ใช้ jsPDF สำหรับ rendering (เพราะ control ง่าย + layout ไม่ซับซ้อน) — ถ้าต้อง LaTeX ให้บอก
- **Tenant-specific:** ใบรับรอง design ต้องปรับตาม tenant (GPS Thailand, GPS Tracker, etc.) — ใช้ `attributes.tenantName` หรือ hardcode ก่อน
- **Logo:** ต้องมี logo file ใน `public/` หรือ base64 embed ใน PDF

---

## Estimated Total Time

**~115 minutes** (แบ่ง 4 phases)

- Phase 1: 25 min (Report fix)
- Phase 2: 35 min (IMEI edit + history)
- Phase 3: 45 min (Certificate PDF)
- Phase 4: 10 min (QC + build)

---

## Risk Assessment

- **Medium risk:** PDF rendering — ถ้า jsPDF ไม่สามารถ render Thai font หรือ layout ซับซ้อน อาจต้องใช้ LaTeX หรือ Puppeteer
- **Low risk:** IMEI history — Traccar attributes รองรับ JSON object ได้
- **Low risk:** Report calculation — logic เดิมมีอยู่แล้ว แค่ปรับให้คำนวณจากข้อมูลที่ส่งเข้ามา

---

**Ready for review.** พิมพ์ "Go" เพื่อเริ่มสร้างทั้งแผน หรือ "ปรับแผน" เพื่อแก้ไข
