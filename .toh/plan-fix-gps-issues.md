# แผนแก้ไข GPS Issues — admin_gpsthailand

**Status:** draft
**Created:** 2026-08-26
**Agent:** plan-orchestrator

---

## 🎯 Goal

แก้ปัญหา GPS offline และ timestamp ผิดพลาดสำหรับบัญชี admin_gpsthailand

**ปัญหาที่พบ:**
1. ✅ Timestamp อนาคต (6 คัน: 2028-2080) — GPS device clock ผิด
2. ✅ ไม่มี GPS Model field ในระบบ (206/206 คัน)
3. ✅ 177/206 คัน (86%) ไม่เคยส่งข้อมูล

---

## 🛠 Stack

- Frontend: React + TypeScript + Traccar API
- Backend: Traccar 6.14.5
- Database: PostgreSQL (ผ่าน Traccar)

---

## 📄 Pages/Components Affected

1. `src/pages/FleetPage.tsx` — เพิ่มคอลัมน์ GPS Model
2. `src/pages/VehicleDetailPage.tsx` — แสดง GPS Model + alert timestamp ผิด
3. `src/components/forms/VehicleForm.tsx` — เพิ่ม dropdown GPS Model
4. `src/types/traccar.types.ts` — เพิ่ม model field
5. `src/lib/gpsModels.ts` — (NEW) รายการ GPS models + protocols

---

## ✅ Done When

- [x] เพิ่ม GPS Model dropdown ใน Vehicle form (12 models ตาม CLAUDE.md)
- [x] แสดงคอลัมน์ Model ใน Fleet table
- [x] Warning badge สำหรับ timestamp อนาคต (> 1 วัน)
- [x] Detail page แสดงปัญหา timestamp พร้อมคำแนะนำ
- [x] `npm run build` ผ่าน
- [x] รายงานให้ลูกค้าว่ารถไหนต้องตั้งนาฬิกา GPS ใหม่

---

## 📐 Phases

### Phase 1: GPS Model Infrastructure
**เป้าหมาย:** สร้าง GPS Model constants + types

- [ ] **T001** `dev-builder` — สร้าง `src/lib/gpsModels.ts` [P]
  - Export `GPS_MODELS` array: 12 models (GT06, Teltonika, OsmAnd, GPS103, TK103, H02, Meitrack, Queclink, Ruptela, Wialon, iStartek, Watch)
  - แต่ละ model มี: `{ id, name, protocols, ports, description }`
  - Export `getModelById()`, `getProtocolsByModel()`

- [ ] **T002** `dev-builder` — เพิ่ม `model` field ใน `traccar.types.ts` [P]
  - Add `model?: string` to `TraccarDevice`
  - Add JSDoc comment

**Checkpoint T002:** Types compile, no errors

---

### Phase 2: Vehicle Form with GPS Model
**เป้าหมาย:** ให้ admin เลือก GPS Model ได้

- [ ] **T003** `ui-builder` — เพิ่ม GPS Model dropdown ใน `VehicleForm.tsx`
  - Import `GPS_MODELS` from lib
  - Add `<Select>` component after uniqueId field
  - Options จาก `GPS_MODELS.map()`
  - Label: "GPS Model (รุ่นกล่อง)"
  - Placeholder: "เลือกรุ่นกล่อง GPS"

- [ ] **T004** `dev-builder` — Connect form to Traccar API
  - Update `traccarService.updateDevice()` to send `model` field
  - Add validation: required when creating new device

**Checkpoint T004:** Form saves model to Traccar, reload shows selected model

---

### Phase 3: Display Model in Fleet Table
**เป้าหมาย:** แสดง Model column ใน Fleet page

- [ ] **T005** `ui-builder` — เพิ่มคอลัมน์ Model ใน `FleetPage.tsx`
  - Add column after "ทะเบียน"
  - Show `device.model || "ไม่ระบุ"`
  - Truncate if > 20 chars

**Checkpoint T005:** Fleet table แสดงคอลัมน์ Model

---

### Phase 4: Timestamp Validation & Warning
**เป้าหมาย:** เตือนเมื่อ timestamp ผิดปกติ

- [ ] **T006** `dev-builder` — สร้าง `src/lib/timestampValidator.ts`
  - Export `isTimestampInFuture(timestamp: string): boolean`
  - Export `getTimestampWarning(timestamp: string): string | null`
  - Check if > 1 day in future → "นาฬิกา GPS ตั้งผิด"

- [ ] **T007** `ui-builder` — แสดง warning badge ใน VehicleDetailPage
  - Import `getTimestampWarning()`
  - Show alert box if warning exists
  - แนะนำ: "ติดต่อผู้ติดตั้งเพื่อตั้งนาฬิกา GPS ใหม่"

**Checkpoint T007:** รถที่มี timestamp 2080 แสดง warning

---

### Phase 5: Customer Report
**เป้าหมาย:** รายงานปัญหาให้ลูกค้า

- [ ] **T008** `plan-orchestrator` — สร้าง `.toh/customer-report-th.md`
  - รายการรถ 6 คันที่ timestamp ผิด
  - คำแนะนำแก้ไข (ภาษาไทย)
  - รายการรถ 177 คันที่ไม่มี Position → ต้องเช็คกล่อง/ซิม

**Checkpoint T008:** ไฟล์รายงานพร้อมส่งลูกค้า

---

### Phase 6: Build & Verify
**เป้าหมาย:** ตรวจสอบว่าทุกอย่างทำงาน

- [ ] **T009** `test-runner` — Run build + type check
  - `npm run build` (must exit 0)
  - `npm run lint` (must exit 0)

**Checkpoint T009:** Build สำเร็จ, zero errors

---

## 📊 Estimated Timeline

- Phase 1-2: ~8 min (infra + form)
- Phase 3-4: ~6 min (display + validation)
- Phase 5-6: ~3 min (report + verify)
- **Total: ~17 นาที**

---

## 🚦 Status: draft

**พร้อม Go?**
1. **Go** — สร้างทั้งแผนอัตโนมัติ ไม่หยุดถามระหว่างทาง
2. **ปรับแผน** — บอกได้เลยว่าแก้ตรงไหน
3. **เก็บไว้ก่อน** — แผนอยู่ที่ `.toh/plan-fix-gps-issues.md`
