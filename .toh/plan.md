# Auto-Enroll All Vehicles for Billing

**Status:** approved  
**Created:** 2026-08-31  
**Goal:** เริ่มเก็บค่าบริการทุกคัน ตั้งแต่ 15 ก.ย. 2569

---

## Goal

สร้าง subscription records สำหรับทุกยานพาหนะที่มี IMEI ในระบบ Traccar โดยอัตโนมัติ พร้อมกำหนด start_date = 15 กันยายน 2569 และรักษาฟังก์ชัน admin ให้ครบถ้วน

**Done When:**
- ✅ Script ดึงยานพาหนะทั้งหมดจาก Traccar
- ✅ สร้าง subscription records ใน billing_subscriptions
- ✅ Start date = 2026-09-15, End date = 2027-03-15 (6 เดือน)
- ✅ Admin page ยังจัดการได้ครบ (change plan, manual payment, etc.)
- ✅ ระบบทดสอบแล้วทำงานได้

---

## Tasks

### Phase 1: Auto-enrollment Script

- [ ] **T001** `backend-connector` — Create enrollment script  
  **Files:** `scripts/enroll-all-vehicles.ts`  
  **Details:**
  - Fetch all devices from Traccar API
  - Filter: only devices with IMEI (uniqueId)
  - Create billing_subscriptions for each
  - Fields: device_id, deviceImei, planId (default: pro), status: active
  - start_date: 2026-09-15, end_date: 2027-03-15
  - Skip if already exists

- [ ] **T002** `dev-builder` — Add CLI command runner  
  **Files:** `scripts/package.json`, `scripts/run-enrollment.sh`  
  **Details:**
  - Make script executable
  - Add environment variable loading
  - Log progress to console

**Checkpoint:** Script runs successfully, creates subscriptions

---

### Phase 2: Admin Enhancements

- [ ] **T003** `ui-builder` — Add bulk actions to admin page  
  **Files:** `src/pages/admin/BillingAdminPage.tsx`  
  **Details:**
  - Button: "Enroll New Vehicles" (manual trigger)
  - Shows count of enrolled vs total devices
  - Can adjust start_date before enrollment

- [ ] **T004** `dev-builder` — Verify admin features intact  
  **Files:** `src/pages/admin/BillingAdminPage.tsx`  
  **Details:**
  - Check: change plan still works
  - Check: mark paid manual still works
  - Check: adjust dates still works
  - No breaking changes

**Checkpoint:** Admin can enroll + manage all subscriptions

---

### Phase 3: Verification

- [ ] **T005** `test-runner` — Test enrollment + admin features  
  **Files:** Manual testing checklist  
  **Details:**
  - Run enrollment script
  - Verify subscriptions created (count matches devices)
  - Test admin: change plan → works
  - Test admin: manual mark paid → works
  - Test admin: adjust dates → works

**Checkpoint:** All features working, no regressions

---

## Timeline

- **Start Date:** 15 กันยายน 2569 (2026-09-15)
- **First Payment Due:** 15 มีนาคม 2570 (2027-03-15)
- **Billing Cycle:** 6 months

---

## Notes

1. Existing subscriptions (from previous manual enrollments) will be skipped
2. Default plan: Pro (฿210/6 months)
3. Admin can change plan after enrollment
4. All vehicles start as "active" status

---

**Status:** approved (starting execution)
