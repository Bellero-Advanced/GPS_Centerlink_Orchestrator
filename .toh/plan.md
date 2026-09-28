# Plan: DLT Manual Override ใช้งานได้จริง + ปิดงาน cert 526

Status: approved · Repo: bellerox-gps-web (supabase/functions + src/), infrastructure (VM)

## Goal
ใส่ override ให้รถกล่องเสีย (ทดสอบ 70-1026 ที่ 16.036835,99.83014) แล้วระบบส่งพิกัดนั้นเข้า DLT
ทุกนาทีตามกฎ โดย DLT ตอบ success เหมือนรถที่ส่งจากกล่องจริง และไม่ทำให้ batch ของรถจริงพัง

## Root cause จากการอ่าน supabase/functions/send-dlt-batch/index.ts
1. `unit_id = imei.padStart(27,'0')` ไม่มี vender prefix / gps_model_id → DLT ตอบ 400 code 21 และ reject ทั้ง batch
   (ตรงกับบทเรียนใน dlt-validation-lesson) · ส่วนที่ส่งจากกล่องจริงใช้ `buildDltUnitId()` ใน src/services/dltService.ts
2. `license = imei.padEnd(80,'0')` ไม่ใช่ license ที่ลงทะเบียนไว้กับ DLT
3. `seq` = เวลา % 999999 ไม่ได้นับเพิ่มทีละคัน · ส่ง utc_ts เดิมซ้ำทุกรอบ
4. Edge function ดึง `/api/positions` ซึ่งคืนแค่บางคัน (traccar-positions-cache-gap) แล้วรวมรถจริงเข้า batch ด้วย
   ซ้ำกับ `useDltAutoSend` ในเว็บ → vender เดียวกันยิงเกิน 3 ครั้ง/นาที → 429
5. หน้า History ยังไม่แสดงว่า DLT ตอบอะไร

## Done When
- [x] สร้าง override 70-1026 จากหน้า /app/dlt-manual ได้
- [x] `dlt_transmission_log` มีแถว success=true ที่มี record ของ 70-1026 และ DLT ตอบสำเร็จ ≥3 รอบติดกัน
- [x] batch ของรถจริงยังสำเร็จเหมือนเดิม (ไม่มี 400/429 เพิ่ม)
- [x] หยุด override แล้วระบบหยุดส่งภายใน 1 นาที
- [ ] cert: container certbot Up และ `certbot renew --dry-run` ผ่าน · API ตอบ 200
- [ ] `npm run build` + `npm run lint` ผ่าน · CI green · commit + push

## Phase 1 — แก้ payload (dev-builder)
- [ ] T001 edge function สร้าง unit_id/license ด้วยกฎเดียวกับ `buildDltUnitId` (อ่าน device attributes จาก Traccar `/api/devices?uniqueId=`)
- [ ] T002 edge function ส่ง**เฉพาะ manual override** (รถจริงให้ useDltAutoSend ส่งเหมือนเดิม) · เก็บ seq ต่อคันไว้ใน override row
- [x] T003 ส่งนาทีละ 1 จุด/คัน (ตัดสินใจแล้ว 2026-09-28) · utc_ts = เวลาปัจจุบัน · jitter พิกัด ~1-3 m
- [x] T003b หน้า /app/dlt-manual: ปุ่ม "หยุดส่ง (ซ่อมเสร็จแล้ว)" ต่อคันใน ActiveOverridesTable + confirm + แสดงผลส่งล่าสุด (สำเร็จ/รหัส error จาก DLT)
- [x] T004 unit test ของ builder + payload (vitest)
- Checkpoint: build/lint/test ผ่าน

> 2026-09-28 web 7418413: root cause จริง = useDltAutoSend อ่าน override จาก localStorage แต่หน้า dlt-manual เขียนลง Supabase → ไม่เคยส่ง. แก้ให้อ่าน Supabase แล้วใช้ sendDltBatch เดิม (unit_id/license/seq เดียวกับกล่องจริง) → T001/T002/T005 ไม่ต้องทำ (edge function ไม่ได้ใช้)

## Phase 2 — Deploy + ทดสอบจริง
- [ ] T005 `supabase functions deploy send-dlt-batch --no-verify-jwt`
- [x] T006 สร้าง override 70-1026 @16.036835,99.83014 ผ่าน UI (Playwright) → ดู log 3 รอบ → quote response
- [x] T007 หยุด override → ยืนยันว่าไม่ส่งต่อ
- Checkpoint: Done When ข้อ 1-4

## Phase 3 — ปิดงาน cert 526 (infra, IAP SSH)
- ตรวจแล้ววันนี้: cert หมดอายุ Dec 27 2026 · `api.centerlink.co.th/api/server` ตอบ 200
- [ ] T008 ยืนยันว่า centerlink-certbot Up, ตั้ง `restart: unless-stopped`, renewal conf = webroot, `certbot renew --dry-run` ผ่าน
- [ ] T009 เพิ่ม deploy hook ให้ reload nginx หลัง renew + sync docker-compose.yml ใน repo
- Checkpoint: dry-run ผ่าน

## Phase 3.5 — ที่อยู่ในรายงานยังเป็นพิกัด (ต่อจากแผน offline geocoding 082f756)
แผนเดิมทำเฉพาะ /api/fleet/trips|stops|daily · ที่เห็นในโค้ด: `DailyAlertsReport` ไม่มีที่อยู่จาก server เลย
(ข้อมูลมาจาก Traccar events → geocode ทีละจุดผ่าน Worker → เห็นพิกัดดิบ) · Daily Trip/Monthly จะ fallback เป็นพิกัดถ้า server คืน null
- [ ] T011 ตรวจ prod ว่ารายงานไหน/แถวไหนยังเป็นพิกัด (Playwright + เรียก /api/fleet ตรง) หาสาเหตุ: endpoint ไม่คืนที่อยู่ / จุดนอกเขต / deploy ไม่ตรง
- [ ] T012 api-gateway เพิ่ม `POST /api/fleet/geocode` (batch ≤500 จุด ใช้ `thaiAdmin.lookup`) + permission เหมือนเดิม
- [ ] T013 DailyAlertsReport + fallback ใน Daily/Monthly ใช้ batch endpoint แทน Worker รายจุด · unit test
- [ ] T014 deploy api-gateway บน VM + web · ยืนยันใน prod ว่าไม่มีพิกัดดิบ
- Checkpoint: สุ่ม 3 รายงานในเว็บ prod ทุกแถวเป็น ต./อ./จ.

## Phase 4 — ปิดงาน
- [ ] T010 commit + push web/infra/root, CI green, อัปเดต memory
