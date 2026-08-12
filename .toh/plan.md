# Plan: DLT Portal ไม่แสดง — Deep Diagnosis + Fix

**Created:** 2026-08-12
**Status:** draft

---

## 🎯 Goal

**แก้ปัญหา DLT Portal ไม่แสดงรถที่กำลังส่งอัตโนมัติ (15-16 คัน) แม้ว่า API บอก "สำเร็จทั้งหมด"**

---

## 📊 Current State

- **รถที่เปิด auto-send:** 15-16 คัน
- **API response:** `code: 1`, `received_records: 15-16` ✅
- **DLT Portal:** ไม่แสดงรถสีเขียว ❌
- **Commit ล่าสุด:** `4c63c10` — revert license เป็น unit_id format
- **Previous fix attempt:** Masterfile sync UI (done) แต่ยังไม่แก้ปัญหา

---

## 🔍 Root Cause Hypothesis

**3 สาเหตุที่เป็นไปได้:**

1. **License เป็นตัวเลขล้วน (ไม่มีตัวอักษร A-Z)**
   ```typescript
   // dltService.ts:369
   const unitId = buildDltUnitId(device, venderId);  // "052000300000359857082980301"
   const license = unitId.padEnd(80, '0');           // 80 ตัวเลขล้วน ❌
   ```
   DLT validation (line 422-425):
   ```typescript
   if (!/[a-zA-Z]/.test(loc.license)) {
     errs.push(`license เป็นตัวเลขล้วน — DLT ต้องการอย่างน้อย 1 ตัวอักษร (A-Z)`);
   }
   ```

2. **Masterfile ยังไม่ sync กับ license format ปัจจุบัน**
   - Masterfile ลงทะเบียนด้วย format เก่า
   - ส่งด้วย format ใหม่ → Portal ไม่แสดง

3. **gpsModelId ของรถแต่ละคันไม่ถูกต้อง**
   - unit_id ขึ้นต้นด้วย model_id (7 digits)
   - ถ้า model_id ผิด → DLT reject

---

## ✅ Done When

- [ ] **Diagnosis complete** — รู้ว่า root cause คืออะไรจริงๆ (มี evidence)
- [ ] **Vehicle audit** — รู้ว่ารถไหนมีปัญหา + เหตุผล + warnings
- [ ] **License format fixed** — มีตัวอักษร A-Z อย่างน้อย 1 ตัว
- [ ] **Validation passed** — รถทุกคันผ่าน validateDltLocation (warnings = 0)
- [ ] **Masterfile synced** — license ตรงกับที่ลงทะเบียน
- [ ] **Portal shows green** — monitor 2-3 รอบส่ง (2-3 นาที) → รถขึ้นสีเขียว
- [ ] **Build passes** — `npm run build` zero errors
- [ ] **Committed** — git commit + push + CI green

---

## 📦 Stack

**Files:**
- `bellerox-gps-web/src/services/dltService.ts` — mapToLocation, buildDltUnitId, validateDltLocation
- `bellerox-gps-web/src/pages/DLTPage.tsx` — debug logging, per-vehicle preview
- `bellerox-gps-web/src/stores/dltSendStore.ts` — auto-send logic

**Tools:**
- Browser console (DevTools) — debug logs
- Traccar API — device + position data
- DLT Masterfile API — verify registration

---

## 🚀 Phases

### Phase 1: วินิจฉัยลึก (Deep Diagnosis) — 20 min

**Checkpoint:** เข้าใจ root cause ชัดเจน + มี vehicle-by-vehicle audit

**T001** `[P]` root-cause-debugger — วิเคราะห์ console logs
- เปิด browser → DLT Page → DevTools Console
- หา `[DLT DEBUG sendDltBatch]` logs
- เช็คค่าสำคัญ:
  - `vender_id`: ต้องตรงที่ลงทะเบียน
  - `locations_count`: 15-16
  - `first_location.unit_id`: 27 digits
  - `first_location.license`: 80 chars — **มีตัวอักษร A-Z หรือไม่?** ← critical
  - `first_location.license_length`: 80
- เช็ค response:
  - `code`: 1 (success)
  - `received_records`: ควรเท่า locations_count
- **Output:** `.toh/dlt-console-analysis.md` — สรุป findings

**T002** `[P]` root-cause-debugger — Audit รถทีละคัน
- Query Traccar API:
  ```bash
  GET /api/devices?filter=all
  ```
- Filter รถที่ `dltEnabled: true`
- สำหรับแต่ละคัน collect:
  ```typescript
  {
    id: device.id,
    name: device.name,
    uniqueId: device.uniqueId (IMEI),
    contact: device.contact (ทะเบียนรถ),
    gpsModelId: device.attributes.gpsModelId,
    driverLicenseNo: device.attributes.driverLicenseNo,
    chassisNo: device.attributes.chassisNo,
    
    // Preview license ที่จะส่งจริง
    preview: buildDltPreview(device, position, venderId),
    
    // Validation
    warnings: validateDltLocation(preview.loc),
    hasAlphaInLicense: /[a-zA-Z]/.test(preview.loc.license),
  }
  ```
- **Output:** `.toh/dlt-vehicle-audit.md` — ตารางรถทั้งหมด + warnings

**T003** root-cause-debugger — จัดกลุ่มปัญหา
- อ่าน `.toh/dlt-vehicle-audit.md`
- จัดกลุ่ม:
  - Group A: license ไม่มีตัวอักษร (ตัวเลขล้วน)
  - Group B: gpsModelId ไม่ถูกต้อง
  - Group C: driverLicenseNo ขาด
  - Group D: ผ่านทุก validation ✅
- **Output:** append to `.toh/dlt-vehicle-audit.md` — section "Problem Groups"

**Checkpoint 1:** รู้ root cause ชัดเจน + รู้ว่ารถไหนมีปัญหาอะไร

---

### Phase 2: แก้ License Format — 25 min

**Checkpoint:** License มีตัวอักษร A-Z + validation ผ่านทุกคัน

**T004** dev-builder — เลือก license strategy
- อ่าน vehicle audit จาก Phase 1
- ตัดสินใจ strategy:
  
  **Option A: ใช้ contact (ทะเบียนรถ) ถ้ามี**
  ```typescript
  if (device.contact && /[a-zA-Z]/.test(device.contact)) {
    license = sanitize(device.contact).padEnd(80, '0');
  }
  ```
  
  **Option B: Prefix "V" หน้า unit_id**
  ```typescript
  license = ('V' + unitId).padEnd(80, '0');  // "V052000300000..." → มี V แล้ว ✓
  ```
  
  **Option C: ใช้ chassisNo ถ้ามี**
  ```typescript
  if (device.attributes.chassisNo) {
    license = sanitize(chassisNo).padEnd(80, '0');
  }
  ```
  
- **Decision:** เขียนใน `.toh/license-strategy.md` พร้อมเหตุผล

**T005** dev-builder — แก้ mapToLocation function
- **File:** `src/services/dltService.ts` (line 365-369)
- เปลี่ยน:
  ```typescript
  // Before:
  const unitId = buildDltUnitId(device, venderId);
  const license = unitId.padEnd(80, '0');  // ตัวเลขล้วน ❌
  
  // After (implement strategy จาก T004):
  const license = buildDltLicense(device, venderId);  // ต้องมี A-Z ✓
  ```
- เพิ่ม function:
  ```typescript
  function buildDltLicense(device: TraccarDevice, venderId: number): string {
    // Strategy logic here
    // MUST contain [a-zA-Z]
    // MUST be 80 chars
    return license;
  }
  ```

**T006** dev-builder — อัพเดท buildDltPreview
- **File:** `src/services/dltService.ts`
- แก้ `buildDltPreview()` ให้ใช้ `buildDltLicense()` แทน
- เช็คว่า preview แสดง license ใหม่ถูกต้อง

**T007** test-runner — Validate ทุกคัน
- เขียน test script:
  ```typescript
  // Test: validate-all-vehicles.ts
  const devices = await getDevices();
  const dltDevices = devices.filter(d => d.attributes.dltEnabled);
  
  for (const device of dltDevices) {
    const preview = buildDltPreview(device, position, venderId);
    const warnings = validateDltLocation(preview.loc);
    const hasAlpha = /[a-zA-Z]/.test(preview.loc.license);
    
    console.log({
      name: device.name,
      license: preview.loc.license.slice(0, 30) + '...',
      hasAlpha,
      warnings,
    });
  }
  ```
- รัน script
- **Expected:** warnings = 0 ทุกคัน, hasAlpha = true ทุกคัน

**T008** test-runner — Build verification
- `npm run build`
- **Expected:** zero TypeScript errors

**Checkpoint 2:** License format ถูกต้อง + validation ผ่าน 100%

---

### Phase 3: Masterfile Sync (ถ้าจำเป็น) — 15 min

**Checkpoint:** Masterfile ซิงค์กับ license format ใหม่

**T009** dev-builder — Check Masterfile sync status
- **File:** `src/services/dltService.ts`
- ใช้ `checkMasterfileSync(device, cfg)` ที่มีอยู่แล้ว
- เช็คทุกคันที่ dltEnabled:
  ```typescript
  const status = await checkMasterfileSync(device, cfg);
  // status: { inSync, needsUpdate, notRegistered }
  ```
- **Output:** `.toh/masterfile-sync-status.md` — สรุปว่ากี่คันต้องซิงค์

**T010** dev-builder — Auto-sync script (conditional)
- **ถ้า T009 บอกว่า > 5 คันต้องซิงค์:**
  - เขียน script `sync-all-masterfile.ts`
  - Loop ทุกคันที่ needsUpdate:
    ```typescript
    for (const device of needsUpdateDevices) {
      const preview = buildDltPreview(device, position, venderId);
      await masterfileAdd(cfg, {
        unit_id: preview.loc.unit_id,
        license: preview.loc.license,  // ใหม่ — มี A-Z แล้ว
        vehicle_id: device.contact || device.name,
        vehicle_chassis_no: device.attributes.chassisNo || '',
        vehicle_type: 'TRUCK_6W',
        vehicle_register_type: 3,
        card_reader: 0,
        province_code: 10,
      });
      console.log(`✅ Synced: ${device.name}`);
    }
    ```
- รัน script
- **Output:** console log แต่ละคัน

**T011** test-runner — Verify sync complete
- เช็ค DLT Page → Masterfile Status column
- **Expected:** ทุกคันแสดง ✅ ซิงค์แล้ว

**Checkpoint 3:** Masterfile 100% in sync

---

### Phase 4: ทดสอบจริง + Monitor Portal — 10 min

**Checkpoint:** DLT Portal แสดงรถสีเขียว ✓

**T012** test-runner — ทดสอบส่ง DLT
- เปิด DLT Page
- เปิด browser console
- กดปุ่ม "ส่งทันที" หรือรอ auto-send (60s)
- ดู console logs:
  ```javascript
  [DLT DEBUG sendDltBatch] {
    vender_id: 52,
    locations_count: 15,
    first_location: {
      unit_id: "052000300000359857082980301",
      license: "V052000300000359857082980301000...",  // มี "V" ✓
      license_length: 80,
      // ...
    }
  }
  
  // Response:
  { code: 1, received_records: 15, message: "success" }
  ```
- **Expected:**
  - license มีตัวอักษร ✓
  - received_records = locations_count ✓
  - no errors

**T013** test-runner — Monitor DLT Portal
- รอ 2-3 นาที (2-3 รอบส่ง = 60s × 2-3)
- เช็ค DLT Portal: https://dltportal.dlt.go.th
- **Expected:** รถ 15-16 คันขึ้นสีเขียว บน map ✓

**T014** test-runner — Final build + commit
- `npm run build` → zero errors
- `git status` → check modified files
- `git add .`
- `git commit -m "fix: DLT license format — add alphabet prefix for Portal display"`
- `git push origin main`
- เช็ค CI → green ✓

**Checkpoint 4:** Portal แสดงรถ ✓ + Code deployed ✓

---

## 📝 Memory Updates

**After completion:**
- `.toh/memory/active.md` — บันทึก session summary
- `.toh/memory/changelog.md` — บันทึกการแก้ไข
- `.toh/memory/decisions.md` — บันทึก license strategy decision

---

## 🎯 Estimated Time

- Phase 1: 20 min (diagnosis)
- Phase 2: 25 min (fix license)
- Phase 3: 15 min (sync Masterfile — conditional)
- Phase 4: 10 min (test + monitor)
- **Total:** ~70 minutes

---

## 🤖 Agent Assignment

- **T001-T003:** root-cause-debugger (investigation specialist)
- **T004-T006:** dev-builder (logic + API integration)
- **T007-T008:** test-runner (validation + build)
- **T009-T011:** dev-builder (Masterfile sync)
- **T012-T014:** test-runner (end-to-end verification)

---

**Status:** draft
**Next:** รอพี่โตอนุมัติ "Go" เพื่อเริ่ม execution
