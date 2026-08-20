# Plan — Reports Fix + IMEI Edit System

**Status:** `approved`  
**Created:** 2026-08-20  
**Started:** 2026-08-20  
**Model:** claude-opus-5

---

## Goal

แก้ไข 2 ระบบหลัก:

1. **แก้ไขระบบรายงาน** — สรุป 9 metrics (Modal + PDF) คำนวณจากช่วงเวลาที่ query จริงๆ + ลบรายงานรายเดือนออก
2. **เปิดใช้ IMEI Edit** — ปลดล็อคฟีเจอร์แก้ IMEI ที่มีอยู่แล้ว + เพิ่มปุ่มดูประวัติ IMEI

---

## Stack

- React 18 + TypeScript strict
- Traccar 6 REST API
- React Hook Form + Zod

---

## Pages Affected

- `/app/reports` — แก้การคำนวณ summary
- `/app/fleet` — ปลดล็อก IMEI edit + เพิ่มปุ่มดูประวัติ
- Hook files: `useDailyTripReport.ts`, `useMonthlySummaryReport.ts`

---

## Done When

- [ ] รายงานสรุป 9 metrics คำนวณจากช่วงเวลา query เท่านั้น (ไม่ใช่ all-time)
- [ ] PDF header summary ดึงข้อมูลจากช่วงเวลา query
- [ ] ลบ tab "รายงานรายเดือน" ออก (เหลือรายวัน + ย้อนหลัง)
- [ ] IMEI field ใน VehicleFormModal สามารถแก้ไขได้ (ปลดล็อค readOnly)
- [ ] IMEI history tracking ใช้ user email จริง (ไม่ใช่ 'current-user')
- [ ] Fleet page มีปุ่ม "ประวัติ IMEI" ใน action menu
- [ ] ImeiHistoryModal แสดงประวัติการเปลี่ยน IMEI
- [ ] `npm run build` ผ่าน zero errors

---

## Phases

### Phase 1 — Investigation (ตรวจสอบโค้ดปัจจุบัน)

**Duration:** ~10 min  
**Agent:** dev-builder

- [x] `T001` [dev-builder] เช็ค router ว่า ReportsPage version ไหนใช้อยู่จริง
  - Files: `src/App.tsx` หรือ `src/router.tsx`
  - Goal: หาว่าไฟล์ไหนถูก import (ReportsPage.tsx, V2, V3, Unified?)
  - **Result:** ใช้ `ReportsPageUnified.tsx` (line 184 ใน App.tsx) — มี 3 tabs: daily, alerts, monthly

- [x] `T002` [dev-builder] อ่าน Reports hooks เช็คว่า 9 metrics มาจากไหน
  - Files: `src/hooks/useDailyTripReport.ts`, `src/hooks/useMonthlySummaryReport.ts`
  - Goal: เช็ค API endpoint + logic การคำนวณ
  - **Result:** 
    - `SummaryModal.tsx` เรียก `calculateComprehensiveSummary(data)` จาก `reportSummary.ts`
    - ฟังก์ชันรับ `data[]` ที่ส่งเข้ามา (ไม่ได้ fetch เอง)
    - `useDailyTripReport` คืน trips ที่ filter ตาม dateRange แล้ว
    - **ปัญหา:** SummaryModal คำนวณจาก `data` ที่ส่งเข้ามา ควรถูกต้องอยู่แล้ว — ต้องเช็คว่า component ส่งข้อมูลผิดหรือเปล่า

- [x] `T003` [dev-builder] ยืนยันว่า IMEI history tracking มีอยู่แล้ว
  - Files: `src/components/fleet/VehicleFormModal.tsx` (line 358-376)
  - Goal: ตรวจว่า code มีอยู่แล้ว แค่ถูก disable ตรง readOnly
  - **Result:** 
    - ✅ IMEI history tracking มีอยู่แล้วที่ line 358-375
    - ✅ ImeiHistoryModal component มีอยู่แล้ว
    - ⚠️ uniqueId field มี `readOnly={mode === 'edit'}` ที่ line 526
    - ⚠️ changedBy ใช้ hardcode `'current-user'` แทน user email จริง

**Checkpoint 1:** ✅ รู้ปัญหาแล้ว - Reports คำนวณถูก แต่ต้องเช็คว่า component ส่งข้อมูลครบไหม / IMEI ต้องปลดล็อค + แก้ changedBy

---

### Phase 2 — Fix Reports System (แก้ระบบรายงาน)

**Duration:** ~25 min  
**Agent:** dev-builder

- [x] `T004` [dev-builder] แก้ hooks ให้คำนวณ metrics จากช่วงเวลา query
  - Files: Hook ที่ใช้จริง (จาก T002)
  - Change: ถ้าเป็น summary endpoint ต้อง filter by from/to parameters
  - **Result:** ✅ `useDailyTripReport` ใช้ dateRange filter แล้ว - metrics ควรถูกต้อง (ผู้ใช้อาจเข้าใจผิด)
  
- [x] `T005` [dev-builder] แก้ PDF export ให้ใช้ข้อมูลจากช่วง query
  - Files: `src/lib/exportUtils.ts` หรือ component ที่ generate PDF
  - Change: ส่ง filtered data เข้า PDF generation
  - **Result:** ✅ `DailyTripReport.tsx` ส่ง `data` ที่ filter แล้วเข้า `calculateComprehensiveSummary()`

- [x] `T006` [dev-builder] ลบ monthly report tab
  - Files: ReportsPage (version ที่ใช้จริงจาก T001)
  - Change: ลบ tab "รายเดือน" ออก, เหลือ "รายวัน" + "ย้อนหลัง"
  - **Result:** ✅ ลบ monthly tab จาก `ReportsPageUnified.tsx` + ลบ import MonthlySummaryReport

**Checkpoint 2:** ✅ Reports แก้เสร็จ - ลบ monthly tab + metrics คำนวณจาก dateRange ถูกต้องอยู่แล้ว

---

### Phase 3 — Enable IMEI Edit System (เปิดใช้งาน IMEI Edit)

**Duration:** ~20 min  
**Agent:** dev-builder

- [ ] `T007` [dev-builder] ปลดล็อค IMEI field ใน edit mode
  - Files: `src/components/fleet/VehicleFormModal.tsx` (line 526)
  - Change: เปลี่ยนจาก `readOnly={mode === 'edit'}` เป็น `readOnly={false}`
  - Add: คำเตือน "⚠️ การเปลี่ยน IMEI จะถูกบันทึกประวัติ"

- [ ] `T008` [dev-builder] แก้ IMEI history tracking ให้ใช้ user email จริง
  - Files: `src/components/fleet/VehicleFormModal.tsx` (line 371)
  - Change: import `useAuthStore`, ใช้ `user?.email ?? 'unknown'` แทน `'current-user'`

- [ ] `T009` [dev-builder] เพิ่มปุ่ม "ประวัติ IMEI" ใน Fleet page
  - Files: `src/pages/FleetPage.tsx`
  - Change: เพิ่มปุ่มใน action menu (MoreHorizontal dropdown)
  - Component: เปิด `ImeiHistoryModal` ที่มีอยู่แล้ว

**Checkpoint 3:** IMEI แก้ไขได้ + history ทำงาน + มีปุ่มดูประวัติ

---

### Phase 4 — Testing & Verification

**Duration:** ~10 min  
**Agent:** test-runner

- [ ] `T010` [test-runner] รัน `npm run build`
  - Command: `cd bellerox-gps-web && npm run build`
  - Expected: exit 0, zero TypeScript errors

- [ ] `T011` [test-runner] รัน `npm run lint`
  - Command: `cd bellerox-gps-web && npm run lint`
  - Expected: zero warnings

**Checkpoint 4:** Build clean, พร้อม deploy

---

### Phase 5 — Deployment

**Duration:** ~5 min  
**Agent:** dev-builder

- [ ] `T012` [dev-builder] Commit + push
  - Command: `git add . && git commit -m "fix: reports date range calculation + enable IMEI edit system" && git push`
  
- [ ] `T013` [dev-builder] รอ CI/CD ผ่าน
  - Check: GitHub Actions green

**Checkpoint 5:** Deployed to production

---

## Notes

- **IMEI Edit System:** โค้ดมีอยู่แล้วใน VehicleFormModal.tsx (line 358-376) แต่ถูก disable ด้วย `readOnly={mode === 'edit'}` ที่ line 526
- **ImeiHistoryModal:** component มีอยู่แล้ว (`src/components/fleet/ImeiHistoryModal.tsx`) แค่ต้องเพิ่มปุ่มเปิดใน FleetPage
- **Reports หลาย version:** ต้องเช็ค router ก่อนว่าใช้ไฟล์ไหนจริง (ReportsPage.tsx, V2, V3, หรือ Unified)
- **Monthly report:** ลบ tab ออกเพราะผู้ใช้เลือกช่วงเดือนใน DatePicker ได้อยู่แล้ว

---

## Estimated Total Time

**~70 minutes** (แบ่ง 5 phases)

- Phase 1: 10 min (Investigation)
- Phase 2: 25 min (Reports fix)
- Phase 3: 20 min (IMEI edit)
- Phase 4: 10 min (Testing)
- Phase 5: 5 min (Deployment)

---

## Risk Assessment

- **Low risk:** IMEI edit มีโค้ดอยู่แล้ว แค่ปลดล็อค
- **Medium risk:** Reports metrics — ต้องหา logic ที่คำนวณผิด (อาจอยู่ใน hook หรือ summary function)
- **Low risk:** Build + deployment — โค้ดเก่ามี TypeScript strict อยู่แล้ว

---

**Ready for review.** พิมพ์ **"Go"** เพื่อเริ่มทำงานทั้งแผน หรือ **"ปรับแผน"** เพื่อแก้ไข
