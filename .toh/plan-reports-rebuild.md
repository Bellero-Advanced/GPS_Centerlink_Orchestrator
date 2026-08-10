# 🔧 รื้อสร้าง Reports Table ใหม่ — Horizontal Scroll ที่ทำงานจริง

**Status:** approved ✅
**Created:** 2026-08-09
**Agent:** plan-orchestrator

**Request:** รื้อ SimpleReportTable ทิ้ง สร้างตารางใหม่ที่มี horizontal scroll ทำงานได้จริง สำหรับ 3 report types (รายวัน, ข้อมูลหลัก, รายเดือน)

---

## 🎯 Goal

สร้างระบบตารางใหม่ที่ horizontal scroll **ทำงานได้จริง 100%** แทนที่ SimpleReportTable เดิม

---

## ✅ Done When

- [ ] ตารางใหม่แสดง horizontal scrollbar เมื่อ columns เกินจอ
- [ ] เลื่อน scrollbar เห็น 18 columns ทั้งหมด
- [ ] First column (ชื่อสินทรัพย์) sticky — เลื่อนแล้วเห็นเสมอ
- [ ] ทดสอบ 3 report types ทั้งหมดทำงานถูกต้อง
- [ ] `npm run build` ผ่าน zero errors
- [ ] Layout responsive 375px - 1920px

---

## 📋 Phases

### Phase 1: สร้าง ReportsTable Component ใหม่

- [ ] **T001** `ui-builder` — สร้าง ReportsTable.tsx ใหม่
  - File: `src/components/reports/ReportsTable.tsx` (NEW)

**Checkpoint 1.1:** ReportsTable component created

---

### Phase 2: แทนที่ SimpleReportTable ใน 3 Reports

- [ ] **T002** `ui-builder` — Update DailyTripReport.tsx
- [ ] **T003** `ui-builder` — Update SummaryReport.tsx
- [ ] **T004** `ui-builder` — Update StopsReport.tsx

**Checkpoint 2.1:** ทั้ง 3 reports ใช้ ReportsTable แล้ว

---

### Phase 3: ลบ SimpleReportTable เดิม

- [ ] **T005** `ui-builder` — ลบ SimpleReportTable.tsx

**Checkpoint 3.1:** SimpleReportTable ถูกลบแล้ว

---

### Phase 4: QC & Verify

- [ ] **T006** `test-runner` — Build & Test

**Checkpoint 4.1:** ทุก report type ผ่านการทดสอบ
