# Plan: DLT Manual Override (ส่งข้อมูลพาหนะแบบ manual ตอนกล่อง GPS เสีย)
Status: draft
Created: 2026-09-20 by /toh-plan

## Goal
เมื่อกล่อง GPS ของรถคันใดคันหนึ่งเสีย และทีม service ต้องใช้เวลาหลายวันเดินทางไปซ่อม/เปลี่ยน
รถคันนั้นจะหยุดส่งข้อมูลให้ DLT → เกิดช่องโหว่ compliance ระบบนี้ให้ admin กรอก
ละติจูด/ลองจิจูด + เลือกสถานะรถเอง แล้วระบบจะส่งข้อมูล manual นั้นให้ DLT แทนข้อมูลจากกล่อง
โดยใช้เวลา "ตอนนี้" (Thai time) เป็น timestamp → DLT ไม่รู้ว่ากล่องพัง มีปุ่ม เริ่มส่ง/หยุดส่ง
เฉพาะระบบนี้ + history ทุกครั้งที่ทำ

## Decisions (assumed — แก้ได้ที่ด่าน Go)
- **รันในเบราว์เซอร์** เหมือน DLT ปัจจุบัน (เปิดแท็บค้างไว้) — ไม่ต้องแตะ server/infra
  ⚠️ ข้อจำกัด: ต้องเปิดแท็บ/คอมพิวเตอร์ค้างไว้ตลอดช่วงที่กล่องพัง (เหมือน auto-send เดิม)
- **ผู้ส่งเดียว (unified sender):** manual override ถูก substitute เข้า batch ของ auto-send เดิม
  → ไม่มี sender ที่สอง, ไม่ชน rate-limit 3/min, ไม่ส่งซ้ำ, ไม่ poison batch
- **History เก็บใน localStorage** (เหมือน txLog เดิม) + sync active overrides ไป Traccar user
  attributes เพื่อให้รอดข้ามแท็บ/ข้ามเครื่อง (Supabase ไม่ได้ config ใน app หลัก)
- **timestamp = `new Date().toISOString()`** (true UTC now) → DLT render +7 = เวลาไทยตอนนี้, ผ่าน freshness gate เสมอ
- **ฟิลด์:** lat/lng (必填) + สถานะรถ (วิ่ง/จอดติดเครื่อง/ดับเครื่อง → engine_status+speed) + speed (แก้ได้) + course + เหตุผล
- **ปุ่ม "ใช้พิกัดล่าสุด":** ดึง last-known GPS position มาเติม lat/lng อัตโนมัติ

## Stack
- React 18 + Vite + TypeScript strict · Zustand (store ใหม่, persist localStorage)
- React Query (mutations) · react-leaflet (map picker) · react-hot-toast
- Reuse: `dltService.ts` (buildDltUnitId/nextSeq/postToDlt/claimDltSendSlot/validateDltLocation)
- Traccar user attributes (server-sync) · Sarabun font · DESIGN.md tokens

## Pages
| Page | Route | Purpose |
|------|-------|---------|
| DLT Manual | `/app/dlt-manual` | จัดการ manual override: เพิ่ม/แก้/เริ่ม-หยุด/ลบ + history + export |

## Done When
- [ ] `npm run build` exits 0 · `npm run lint` ไม่มี warning ใหม่ · `npm run test` ผ่าน
- [ ] `/app/dlt-manual` render ไม่มี console error
- [ ] เพิ่ม override → ภายใน 1 รอบ 60s (หรือ "ส่งทันที") ถูกส่งไป DLT ด้วย utc_ts≈now + lat/lng/status ตามที่กรอก → ขึ้น history = success
- [ ] รถที่มี override ถูก **กันออก** จาก auto-send ปกติ (ไม่ส่ง GPS ค้าง/ไม่ส่งซ้ำ)
- [ ] ปุ่ม เริ่มส่ง/หยุดส่ง ทำงาน: หยุด → ไม่ส่ง manual ต่อ
- [ ] record ที่ unit_id/license ไม่ผ่าน validate ถูก **บล็อกตั้งแต่ตอนกรอก** และไม่ถูกส่ง (batch ไม่พัง)
- [ ] history รอดหลัง reload + export CSV ได้
- [ ] Mobile 375px ใช้ได้ · ข้อความไทย Sarabun · สีสถานะตรง DESIGN.md

## Phase 1 — UI shell (เห็นหน้าจอเร็วสุด)
- [ ] T000 design-reviewer — อ่าน root `DESIGN.md` (มีอยู่แล้ว 49KB ห้าม generate ใหม่) สรุป tokens/components ที่หน้า DLT Manual ต้องใช้ → `.toh/dlt-manual-design-notes.md`
- [ ] T001 [P] ui-builder — page shell + route + nav: `src/pages/DLTManualPage.tsx`, `src/App.tsx` (route `dlt-manual`), `src/components/layout/LayoutV2.tsx` (nav 'DLT Manual (กล่องเสีย)' ภายใต้ 'จัดการ', gate role เหมือน /app/dlt)
- [ ] T002 [P] ui-builder — form เพิ่ม/แก้ override + map picker (click-to-set, ใช้พิกัดล่าสุด): `src/components/dlt/ManualOverrideForm.tsx`
- [ ] T003 [P] ui-builder — ตาราง active overrides (เริ่ม/หยุด/แก้/ลบ) + ตาราง history + empty states: `src/components/dlt/ManualOverrideTable.tsx`, `src/components/dlt/ManualHistoryTable.tsx`
**Checkpoint:** `npm run build` exits 0 AND `/app/dlt-manual` render เห็น form + 2 ตาราง (mock/empty)

## Phase 2 — Data layer (types + store + service)
- [ ] T004 dev-builder — types + store: `src/types/dlt.types.ts` (เพิ่ม `DltManualOverride`, `DltManualLogEntry`, `DltVehicleStatus`), `src/stores/dltManualStore.ts` (Zustand persist `bellerox_dlt_manual_overrides` + `bellerox_dlt_manual_log`, cap 500)
- [ ] T005 dev-builder — service manual: `src/services/dltManualService.ts` (`buildManualLocation` reuse unit_id/license/seq/driver, utc_ts=now; status→engine_status+speed; `validateManualOverride` เรียก `validateDltLocation` + lat/lng range + Thailand bbox warn) — export `buildDltUnitId/nextSeq/postToDlt/claimDltSendSlot` จาก `src/services/dltService.ts`
- [ ] T006 dev-builder — unified send: `src/services/dltService.ts` (`sendDltBatch` รับ `{overrides, includeReal}` → device ไหนมี override ใช้ manual path + skip freshness; กัน override device ออกจาก real path; รวม override device แม้ dltEnabled=false ถ้า unit_id ผ่าน) + `src/hooks/useDltAutoSend.ts` (loop ทำงานเมื่อ `autoSend || manualActive`, `includeReal = autoSend`)
**Checkpoint:** `npx vitest run` unit ผ่าน (buildManualLocation + validate + substitution) AND `npm run build` exits 0

## Phase 3 — History + server-sync + wiring
- [ ] T007 dev-builder — history logging ต่อ DLT response + CSV export: `src/services/dltManualService.ts`, reuse `src/lib/exportUtils.ts`
- [ ] T008 dev-builder — sync active overrides ↔ Traccar user attributes `dltManualOverrides` (load ตอน mount, save เมื่อเปลี่ยน): `src/services/dltManualService.ts`
- [ ] T009 dev-builder — ต่อ UI↔store↔service (mutations, toast, master เริ่ม/หยุดส่ง, countdown, "ส่งทันที", ปุ่มใช้พิกัดล่าสุด): `src/pages/DLTManualPage.tsx`, `src/hooks/useDevices.ts` (ถ้าต้อง expose last position)
**Checkpoint:** เริ่ม override → ส่งใน 60s/ส่งทันที → ขึ้น history success → หยุด → ไม่ส่งต่อ · `npm run build` exits 0

## Phase 4 — Tests + review + verify
- [ ] T010 test-runner — unit tests `src/services/__tests__/dltManual.test.ts`: validate reject unit_id/license ผิด (ห้าม poison batch), status→engine/speed mapping, utc_ts≈now ผ่าน freshness, override device ถูกกันจาก real path
- [ ] T011 design-reviewer — Mode B review `DLTManualPage` + components กับ `DESIGN.md` + `AVOID-LIST.md` แก้ violations อัตโนมัติ
- [ ] T012 test-runner — full verify: `npm run build` + `npm run lint` + `npx vitest run` quote ผลจริง
**Checkpoint:** Done When ทุกข้อ green (quote output)

## Notes / Future
- ถ้าต้องการส่งต่อเนื่องแม้ปิดเบราว์เซอร์ → upgrade เป็น Supabase Edge Function + cron (ต้องย้าย DLT credentials ขึ้น server) — ยังไม่ทำในรอบนี้
- ถ้าเจอ rate-limit จากหลายเครื่องหลัง IP เดียว → ต้องย้าย guard ไป server-side (จำกัด已知จาก dlt-validation-lesson)
