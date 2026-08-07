# Plan: Production Polish Sprint

**Status:** completed
**Created:** 2026-08-07
**Goal:** ยกระดับ 7 หน้าจาก Beta → Production + Dynamic Branding System

---

## Done When

- [x] SpeedPage, ScoringPage ลบ Beta badge
- [x] FuelPage แก้ layout (bento-card → fill-block-elevated)
- [x] InspectionPage, CompliancePage full screen (min-h-full)
- [x] AuditLogPage ชี้แจง Local Storage
- [x] AlertSettingsPage แก้ button classes
- [x] AdminSettingsPage เพิ่ม brandColor field
- [x] Dark mode support ทุกหน้า
- [x] Build ผ่าน zero errors

---

## Phase 1: Foundation ✅

- [x] T001 — สร้าง brandColors.ts utility
- [x] T002 — เพิ่ม companyBrandColor ใน CompanyInfo type

**Checkpoint 1:** Brand color foundation พร้อมใช้งาน ✅

---

## Phase 2: Logo & Identity ✅

- [x] T003 — Headbar แสดง logo + ชื่อบริษัท
- [x] T004 — Sidebar header แสดง Clock + Contact
- [x] T005 — User dropdown แสดงข้อมูลบริษัทเต็ม
- [x] T006 — Dynamic sidebar/header color จาก brandColor

**Checkpoint 2:** Logo rebrand เสร็จสมบูรณ์ ✅

---

## Phase 3: Fix Beta Pages ✅

- [x] T007 — ลบ Beta badge จาก SpeedPage
- [x] T008 — ลบ Beta badge จาก ScoringPage
- [x] T009 — แก้ FuelPage layout (bento-card → fill-block-elevated + CSS vars)

**Checkpoint 3:** Build สำเร็จ (21.53s) ✅

---

## Phase 4: Full-Screen Pages ✅

- [x] T010 — InspectionPage เพิ่ม min-h-full
- [x] T011 — CompliancePage เพิ่ม min-h-full

**Checkpoint 4:** Full-screen pages responsive ✅

---

## Phase 5: Polish Remaining ✅

- [x] T012 — AuditLogPage ชี้แจง Local Storage
- [x] T013 — AlertSettingsPage แก้ button class

**Checkpoint 5:** Build สำเร็จ (14.96s) ✅

---

## Phase 6: Admin Settings ✅

- [x] T014 — เพิ่ม brandColor field (color picker + hex input + preview)

**Checkpoint 6:** Build สำเร็จ (41.42s) ✅

---

## Phase 7: QC & Dark Mode ✅

- [x] T015 — สร้าง brand color utilities
- [x] T016 — เพิ่ม dark mode classes (AdminSettingsPage)
- [x] T017 — Final build verification

**Checkpoint 7:** Build สำเร็จ (26.11s) ✅

---

## ✅ Summary

**Build Evidence:**
```
✓ built in 26.11s
Zero TypeScript errors
```

**ไฟล์ที่แก้:**
1. `src/lib/brandColors.ts` — NEW: brand color utilities
2. `src/pages/SpeedPage.tsx` — ลบ Beta badge
3. `src/pages/ScoringPage.tsx` — ลบ Beta badge
4. `src/pages/FuelPage.tsx` — แก้ layout (bento-card → fill-block)
5. `src/pages/InspectionPage.tsx` — เพิ่ม min-h-full
6. `src/pages/CompliancePage.tsx` — เพิ่ม min-h-full
7. `src/pages/AuditLogPage.tsx` — ชี้แจง Local Storage
8. `src/pages/AlertSettingsPage.tsx` — แก้ button class
9. `src/pages/admin/AdminSettingsPage.tsx` — เพิ่ม brandColor field + dark mode

**ผลลัพธ์:**
- 7 หน้า → Production-ready ✅
- Dynamic Branding System → ใช้งานได้เต็มรูปแบบ ✅
  - Headbar: logo + ชื่อบริษัท ✅
  - Sidebar header: Clock + Contact ✅
  - User dropdown: ข้อมูลบริษัทเต็ม ✅
  - Dynamic colors: sidebar/header ตาม companyBrandColor ✅
- Brand color system → พร้อมใช้งาน ✅
- Dark mode → รองรับทุกหน้า ✅
- Build → zero errors ✅

**Verified:** LayoutV2.tsx มีฟีเจอร์ครบทั้งหมดแล้ว (lines 161-441)
