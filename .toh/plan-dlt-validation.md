# แผน: DLT Validation System — ป้องกัน Admin ตั้งค่าผิด

**Goal:** เพิ่ม validation + warning system เพื่อตรวจจับ `gpsModelId` ผิดพลาดก่อนส่ง DLT

**Root Cause:**  
Admin ตั้ง `gpsModelId = 0520005` แต่ใน DLT Portal Masterfile คือ `0520003`  
→ License ไม่ match → Portal ไม่แสดงรถ

---

## Stack
- React 18 + TypeScript
- Zod validation
- Toast notifications
- DLT Service (existing)

---

## Done When
- [x] Admin เห็น warning ถ้า gpsModelId ไม่ match Masterfile format
- [x] DLT Page แสดง mismatch warning สำหรับรถที่ส่งแล้วแต่ไม่แสดงใน Portal
- [x] Validation ตรวจสอบ gpsModelId format (7 digits, ขึ้นต้นด้วย vender_id)
- [x] มี "Test License" button ให้ admin ทดสอบ license ก่อนบันทึก
- [x] Build + commit + CI green

---

## Phases

### Phase 1: เพิ่ม Validation ใน VehicleFormModal
**Checkpoint:** Form แสดง error ถ้า gpsModelId format ผิด

- [T001] ui-builder — เพิ่ม validation rules ใน VehicleFormModal schema
  - gpsModelId ต้องเป็น 7 digits
  - 2 ตัวแรกต้องตรงกับ vender_id (52)
  - File: `src/components/fleet/VehicleFormModal.tsx`

- [T002] ui-builder — เพิ่ม helper text + example
  - แสดง format ที่ถูกต้อง: "052XXXX (7 ตัว)"
  - แสดง example: "0520003 (Meitrack T333)"
  - File: `src/components/fleet/VehicleFormModal.tsx`

### Phase 2: เพิ่ม "Test License" Feature
**Checkpoint:** Admin กดปุ่มแล้วเห็น license ที่จะส่งไป DLT

- [T003] dev-builder — เพิ่ม `calculateLicense()` helper function
  - Input: device attributes (IMEI, gpsModelId, vender_id)
  - Output: { unitId, license, isValid, warnings }
  - File: `src/services/dltService.ts`

- [T004] ui-builder — เพิ่มปุ่ม "ทดสอบ License"
  - แสดง modal preview: unit_id, license (80 chars)
  - แสดง warning ถ้า format ผิดปกติ
  - File: `src/components/fleet/VehicleFormModal.tsx`

### Phase 3: DLT Page Mismatch Warning
**Checkpoint:** DLT Page แสดง warning badge สำหรับรถที่ส่งแล้วแต่อาจมีปัญหา

- [T005] dev-builder — เพิ่ม `detectLicenseMismatch()` logic
  - เช็ครถที่ส่งไป DLT แล้ว (lastSentAt มีค่า)
  - แต่ไม่แสดงใน Portal (ไม่มี feedback)
  - คำนวณ warning score
  - File: `src/services/dltService.ts`

- [T006] ui-builder — เพิ่ม warning badge ในตาราง DLT
  - สีเหลือง "⚠️ อาจมีปัญหา" ถ้า sent แต่ไม่แสดง > 5 นาที
  - Tooltip: "ส่งไปแล้ว แต่ Portal ไม่แสดง → ตรวจสอบ gpsModelId"
  - File: `src/pages/app/dlt/DltPage.tsx`

### Phase 4: GPS Models Registry (SKIP — มีแล้ว)
**Checkpoint:** SearchSelect มีอยู่แล้วในหน้าแก้ไขพาหนะ ✓

- [T007] ~~dev-builder — สร้าง GPS Models registry~~ SKIP
- [T008] ~~ui-builder — เปลี่ยน input เป็น dropdown~~ SKIP (มี SearchSelect อยู่แล้ว)

### Phase 5: Testing + Documentation
**Checkpoint:** ทดสอบทั้ง validation + warning ทำงานถูกต้อง

- [T009] test-runner — ทดสอบ validation
  - กรอก gpsModelId ผิด format → เห็น error
  - กรอกถูก → บันทึกได้
  - npm run build ผ่าน

- [T010] dev-builder — เพิ่ม logging
  - Log license mismatch cases
  - Log validation failures
  - File: `src/services/dltService.ts`

- [T011] ui-builder — อัพเดท UI tooltips
  - เพิ่ม help text ที่ชัดเจน
  - File: `src/components/fleet/VehicleFormModal.tsx`

---

## Status
`approved`

## Estimated Time
~90 นาที (11 tasks, บางตัวขนานได้)

---

## Next Steps After This
1. แก้ gpsModelId ของรถ 2 คัน (70-7160, 70-7642) จาก 0520005 → 0520003
2. ส่ง DLT ใหม่
3. Monitor Portal ว่าขึ้นสีเขียวหรือเปล่า
