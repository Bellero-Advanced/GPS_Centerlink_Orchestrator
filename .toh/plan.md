# Plan: DLT Portal ไม่แสดงข้อมูล — Masterfile Out of Sync

**Goal:** แก้ปัญหา DLT ส่งสำเร็จ แต่ Portal ไม่แสดง (เกิดหลัง deploy commit 4099878 - license format change)

**Root Cause:**
- วันที่ 5 ส.ค. เปลี่ยน license format จาก unit_id → IMEI(15)+65zeros
- Masterfile ที่ลงทะเบียนไว้ยังใช้ license format เก่า
- DLT Portal ไม่รู้จัก license ใหม่ → ข้อมูลถูกรับแต่ไม่แสดง

**Stack:** React 18 + TypeScript + existing DLTPage.tsx + dltService.ts

**Pages:**
- DLTPage.tsx — เพิ่ม Masterfile Sync Checker + Auto Re-register UI
- dltService.ts — เพิ่ม masterfile sync validation logic

**Done When:**
- [x] DLTPage แสดงเตือนเมื่อรถที่เปิด DLT ยังไม่ sync Masterfile หลัง deploy
- [x] มีปุ่ม "ซิงค์ Masterfile" ที่เรียก masterfileAdd ใหม่ด้วย license format ปัจจุบัน
- [x] แสดงสถานะ: ✅ ซิงค์แล้ว | ⚠️ ต้องซิงค์ (license เปลี่ยนหลัง deploy) | ❌ ยังไม่ลงทะเบียน
- [x] `npm run build` ผ่าน (zero errors)

---

## Phase 1: Masterfile Sync Checker

**Checkpoint:** DLTPage แสดงเตือนว่ารถไหนต้องซิงค์ Masterfile ใหม่

- [x] `T001` [P] dev-builder — เพิ่ม masterfile sync validation
  - File: `src/services/dltService.ts`
  - Add: `export async function checkMasterfileSync(device, cfg)` 
  - Logic:
    1. เรียก `masterfileGetByUnit(cfg, buildDltUnitId(device, venderId))`
    2. เทียบ `masterfile.license` vs `buildDltPreview().loc.license`
    3. return `{ inSync: boolean, needsUpdate: boolean, notRegistered: boolean }`
  - Handle 503 error gracefully (Masterfile API ไม่ว่าง → return { unknown: true })

- [x] `T002` [P] ui-builder — เพิ่ม Masterfile Status Column ในตาราง DLT
  - File: `src/pages/DLTPage.tsx`
  - Add column: "สถานะ Masterfile"
  - Show:
    - ✅ ซิงค์แล้ว (inSync=true)
    - ⚠️ ต้องซิงค์ใหม่ (needsUpdate=true) — เน้นสีส้ม
    - ❌ ยังไม่ลงทะเบียน (notRegistered=true) — เน้นสีแดง
    - ❓ ไม่ทราบ (unknown=true) — API 503
  - Use React Query: `useQuery(['masterfileSync', deviceId], () => checkMasterfileSync(...))`

- [x] `T003` [P] test-runner — verify column แสดงสถานะถูกต้อง
  - Test: เปิด DLTPage → เห็นคอลัมน์ "สถานะ Masterfile"
  - Expected: รถที่มี dltEnabled=true แสดงสถานะ (⚠️ ควรเป็นส่วนใหญ่)

---

## Phase 2: Masterfile Re-sync UI

**Checkpoint:** User กดปุ่มซิงค์ → Masterfile อัพเดทด้วย license ใหม่

- [x] `T004` [P] ui-builder — เพิ่มปุ่ม "ซิงค์ Masterfile" ในตาราง
  - File: `src/pages/DLTPage.tsx`
  - Add button column: แสดงเมื่อ `needsUpdate=true` หรือ `notRegistered=true`
  - onClick → เปิด modal confirm พร้อมแสดง:
    - unit_id: xxx (เดิม + ใหม่เหมือนกัน)
    - license: xxx (เดิม) → xxx (ใหม่)
    - ข้อความ: "ซิงค์ Masterfile เพื่ือให้ Portal แสดงข้อมูล GPS"

- [x] `T005` [P] dev-builder — implement masterfile re-sync mutation
  - File: `src/pages/DLTPage.tsx`
  - Add: `useMutation` → calls `masterfileAdd(cfg, entry)`
  - entry fields:
    - unit_id: buildDltUnitId(device, venderId)
    - vehicle_id: device.name หรือ device.contact (ทะเบียนรถ)
    - license: IMEI(15) + 65 zeros (format ปัจจุบัน)
    - vehicle_chassis_no: device.attributes.chassisNo ?? ''
    - vehicle_type: 'TRUCK_6W' (default หรือจาก device.attributes)
    - vehicle_register_type: 3 (รถบรรทุก default)
    - card_reader: 0
    - province_code: 10 (กทม default หรือจาก device.attributes)
  - onSuccess → invalidate `['masterfileSync', deviceId]` → ไอคอนเปลี่ยนเป็น ✅

- [x] `T006` [P] ui-builder — เพิ่ม "ซิงค์ทั้งหมด" button
  - File: `src/pages/DLTPage.tsx`
  - Add: ปุ่มด้านบนตาราง "🔄 ซิงค์ Masterfile ทั้งหมด"
  - onClick → confirm modal → loop ทุกรถที่ needsUpdate=true
  - แสดง progress: "กำลังซิงค์ 3/15 คัน..."
  - onComplete → show summary: "ซิงค์สำเร็จ 14 คัน, ล้มเหลว 1 คัน"

- [x] `T007` [P] test-runner — verify sync ทำงาน + build passes
  - Test: กดปุ่ม "ซิงค์ Masterfile" → เห็น toast สำเร็จ → สถานะเปลี่ยนเป็น ✅
  - Command: `npm run build`
  - Expected: zero errors, Masterfile sync UI working

---

## Phase 3: Auto-Sync Warning Banner

**Checkpoint:** แสดง banner เตือนทันทีเมื่อเข้า DLTPage

- [x] `T008` [P] ui-builder — เพิ่ม warning banner หน้า DLTPage
  - File: `src/pages/DLTPage.tsx`
  - Show banner เมื่อมีรถที่ needsUpdate > 0:
    ```
    ⚠️ ตรวจพบ 12 คัน ที่ต้องซิงค์ Masterfile หลังอัพเกรดระบบ
    [ซิงค์ทั้งหมดเลย] [ดูรายละเอียด]
    ```
  - ปิดได้ (dismiss) แล้วเก็บใน localStorage ไม่แสดงอีก

- [x] `T009` [P] ui-builder — เพิ่ม help text อธิบายปัญหา
  - File: `src/pages/DLTPage.tsx`
  - เพิ่ม info box ใต้ banner:
    ```
    💡 ทำไมต้องซิงค์?
    เมื่อวันที่ 5 ส.ค. ระบบได้อัพเกรดรูปแบบการส่งข้อมูลให้ตรงตามมาตรฐาน DLT
    รถที่ลงทะเบียนก่อนวันนี้ต้องซิงค์ Masterfile ใหม่เพื่อให้ Portal แสดงข้อมูล GPS
    ```

- [x] `T010` [P] test-runner — verify banner + build
  - Test: เปิด DLTPage → เห็น banner → กด "ซิงค์ทั้งหมดเลย" → banner หาย
  - Command: `npm run build`
  - Expected: zero errors

---

**Status:** approved
**Estimated Time:** ~25 minutes (10 tasks, parallel where possible)
**Memory Tier 1:** active.md + summary.md
