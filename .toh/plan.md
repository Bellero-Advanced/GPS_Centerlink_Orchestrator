# Plan: DLT ส่งครบทุกคัน + Auto-index Partition

Status: approved
Created: 2026-08-25 by /toh-plan
Supersedes: plan-2026-08-25-geocode-cache-DONE.md (เสร็จครบ archive แล้ว)

## Goal

**ปัญหา A — DLT ส่งไม่ครบและจำนวนไม่นิ่ง (5→10 คัน สลับไปมา)**
รถเปิด DLT ไว้ **42 คัน** แต่แต่ละรอบส่งได้แค่ 5–10 คัน สาเหตุคือ `useDltAutoSend` ดึงตำแหน่งจาก
`traccarService.getCurrentPositions()` ซึ่งยิง `GET /api/positions` เปล่า — endpoint นี้อ่านจาก
**in-memory cache ของ Traccar เท่านั้น** ไม่ใช่ฐานข้อมูล วัดจริงบน production: คืนแค่ 31–32 แถว
จากรถ 214 คัน และในนั้นเป็นรถที่เปิด DLT อยู่แค่ **8 คัน** ที่เหลือ 34 คันไม่เคยถูกพิจารณาเลย

นี่คือ **บั๊กเดียวกับที่ทำให้ Vehicle Card ว่าง** ซึ่งแก้ไปแล้วใน `b6db3fb` ด้วย `getPositionsByIds()`
แต่แก้แค่ฝั่ง UI — path ของ DLT ยังใช้ของเดิมอยู่ จึงยังพลาดรถเหมือนเดิม

ทำไมจำนวน "ไม่เท่ากันเลย" แต่ละรอบ: cache ของ Traccar หมุนตามลำดับที่ device ส่งเข้ามา รอบหนึ่ง
มีรถเปิด DLT ติดอยู่ 8 คัน อีกรอบ 5 คัน อีกรอบ 10 คัน — เปลี่ยนไปตามจังหวะที่ GPS ยิงเข้ามาพอดี
ไม่ได้เกี่ยวกับ DLT ปฏิเสธ (ทุกแถวในภาพ HTTP 200 · DLT รับ = ส่ง ครบทุกรอบ)

เมื่อเปลี่ยนไปใช้ fallback แบบเดียวกับ Vehicle Card: ดึงได้ **42/42 คัน** ใน 0.197s
กรองด้วยด่าน 15 นาทีแล้วเหลือ **15 คันที่ส่งได้จริง** (จาก 8) — เกือบสองเท่า

**ปัญหา B — 27 คันที่เหลือถูกทิ้งเงียบ ๆ**
ในบรรดารถเปิด DLT 42 คัน มี **25 คันที่ตำแหน่งล่าสุดเก่ากว่า 24 ชั่วโมง** (บางคันเก่า 2 วัน)
คือ GPS ไม่ส่งเข้ามาเลยหรือ SIM หมด — พวกนี้ *ควร* ถูกกรองออกตาม DLT spec แต่ตอนนี้ผู้ใช้
**ไม่มีทางรู้เลยว่าคันไหนหายไปเพราะอะไร** เพราะข้อความบอกแค่จำนวนรวมใน console ไม่ขึ้นบน UI
และอีก **3 คันมี fixTime พังจริง** (`88-9432` = ปี 2080, `89-7270` = ปี 2028, `84-2480` = ปี 2031)
ตัวแก้ Bangkok offset ปัจจุบันจับได้แค่ช่วง +5.5→8.5 ชม. จึงไม่ครอบเคสพังระดับปี

**ปัญหา C — auto-index partition**
มี cron อยู่แล้วที่ VM (`/opt/bellerox/scripts/create-next-month-partition.sh` รันวันที่ 20 ทุกเดือน)
สร้าง partition เดือนถัดไปได้ แต่ **ไฟล์นี้ไม่มีอยู่ใน git เลย** — อยู่แค่บน VM เครื่องเดียว
ถ้า VM หาย/สร้างใหม่ ก็หายไปด้วย และตัว script **ไม่ได้สร้าง index `id`** เอง

ที่ยังไม่พังเพราะ index 3 ตัวบน parent เป็นแบบ partitioned (`CREATE INDEX ... ON ONLY`) → Postgres
สร้างให้ partition ใหม่อัตโนมัติ **แต่ `id` ไม่ได้อยู่ในนั้น** — เดือน ก.ย. มี `_id_idx` เพราะหนู
สร้างเองด้วยมือเมื่อวานนี้ **เดือน ต.ค. จะไม่มี** และอาการช้า 11 วินาทีจะกลับมาทันทีที่ข้ามเดือน

## Stack

ไม่มีของใหม่ — React 18 + React Query (web) · Bash + psql (infra) · ตามกฎ CLAUDE.md เดิมทุกข้อ
(service → hook → component · ไม่มี `any` · ไม่แตะสีสถานะ)

## Done When

1. `useDltAutoSend` ส่งรถที่ตำแหน่งสดครบทุกคัน ไม่ใช่แค่คันที่ติดอยู่ใน cache
   → พิสูจน์: log รอบจริงบอก `42 candidates → N fresh` โดย N ตรงกับที่วัดจาก API ด้วยมือ
2. ตาราง "ประวัติการส่งข้อมูล DLT" มีคอลัมน์บอกจำนวนที่ถูกข้าม + เหตุผลสรุป (ไม่ต้องเปิด console)
3. รถที่ fixTime พังระดับปี ถูกกรองออกและนับแยกเป็น "เวลาผิดปกติ" ไม่ปนกับ "ข้อมูลเก่า"
4. `create-next-month-partition.sh` อยู่ใน git + สร้าง index `id` ให้ partition ใหม่เสมอ
5. มี guard ที่ไล่เติม index ย้อนหลังให้ partition ที่ยังขาด (idempotent — รันซ้ำได้)
6. `npm run build` + `npm run lint` ผ่าน 0 error 0 warning
7. ยืนยันบน production ว่า partition ต.ค. เกิดพร้อม index ครบ 4 ตัว

## Phase 1 — DLT ส่งครบทุกคัน (แก้ต้นตอ)

- [ ] **T001** `dev-builder` — `bellerox-gps-web/src/services/traccarService.ts`
      เพิ่ม `getPositionsForDevices(devices)` ที่รวม cache + fallback `getPositionsByIds()`
      ไว้ที่เดียว (ตอนนี้ logic นี้อยู่ใน `useDevices.ts` ซึ่ง hook อื่นเรียกใช้ไม่ได้)
- [ ] **T002** `dev-builder` — `bellerox-gps-web/src/hooks/useDevices.ts`
      ให้ `useVehiclesWithPositions` เรียกใช้ helper ตัวใหม่ ไม่ให้ logic ซ้ำสองที่
      **ห้ามเปลี่ยนพฤติกรรม `displayStatus`** — ต้องคง `livePos` แยกจาก `pos` ตามที่แก้ไว้ใน `b6db3fb`
- [ ] **T003** `dev-builder` — `bellerox-gps-web/src/hooks/useDltAutoSend.ts`
      เปลี่ยน `doSend` ให้ใช้ helper ตัวใหม่แทน `getCurrentPositions()` เปล่า
      ต้องคง rate-limit guard ผ่าน `localStorage` (`bellerox_dlt_last_send`) ไว้ — ห้ามถอด
- [ ] **Checkpoint 1** — รัน `npm run build` ต้องผ่าน · เทียบจำนวนกับที่วัดด้วยมือ (42 candidates)
      และยืนยันว่าจำนวนรถแต่ละสถานะบน Live Map ไม่เปลี่ยน (กัน regression เดิมซ้ำ)

## Phase 2 — บอกให้ชัดว่าคันไหนหาย เพราะอะไร

- [ ] **T004** `dev-builder` — `bellerox-gps-web/src/services/dltService.ts`
      แยกเหตุผลที่ปฏิเสธเป็นหมวด: `stale` (เก่ากว่า 15 นาที) · `future` (เวลาอนาคต) ·
      `badTimestamp` (พังระดับปี) · `noPosition` — คืนกลับมาใน `DltTxEntry` เป็นตัวเลขต่อหมวด
- [ ] **T005** `dev-builder` — `bellerox-gps-web/src/types/dlt.types.ts`
      เพิ่ม field `skipped` ใน `DltTxEntry` (ต้องอ่าน log เก่าที่ไม่มี field นี้ได้ → optional)
- [ ] **T006** `dev-builder` — `dltService.ts` — ขยาย `adjustForBangkokServer`
      ให้จับ fixTime ที่เพี้ยนเกิน 1 ปี → fallback ไปใช้ `serverTime` แทน (device 3 คันนี้
      `serverTime` ปกติดี ใช้ได้เลย) ถ้า `serverTime` ก็พังด้วยจึงนับเป็น `badTimestamp`
- [ ] **T007** `ui-builder` — `bellerox-gps-web/src/pages/DLTPage.tsx`
      เพิ่มคอลัมน์ "ข้าม" ในตารางประวัติ + tooltip แจกแจงเหตุผล
      ตาม `.claude/rules/ui-design.md`: ใช้ `chip chip-warn` สำหรับข้าม, `row-fill` ไม่ใส่ border
- [ ] **T008** `ui-builder` — `DLTPage.tsx` — แผง "รถที่ส่งไม่ได้" ลิสต์ชื่อคัน + อายุตำแหน่ง
      เรียงจากเก่าน้อยไปมาก เพื่อให้พี่โตรู้ว่าควรไปตาม SIM คันไหนก่อน
- [ ] **Checkpoint 2** — `npm run build` + `npm run lint` ผ่าน · เปิด DLTPage ที่ 375px ได้
      · dark mode ไม่แตก · log เก่าที่ไม่มี `skipped` ยังแสดงได้ไม่ crash

## Phase 3 — Auto-index Partition (infra)

- [ ] **T009** `backend-connector` — `infrastructure/postgres/create-next-month-partition.sh`
      ดึง script จาก VM เข้า git + เพิ่มขั้นสร้าง `<partition>_id_idx` หลังสร้าง partition
      (partition ใหม่ว่างเปล่า → ไม่ต้องใช้ CONCURRENTLY, เร็วและปลอดภัย)
- [ ] **T010** `backend-connector` — ไฟล์เดิม — เพิ่ม loop ไล่เติม index ที่ขาดให้ **ทุก** partition
      ที่มีอยู่ (idempotent ด้วย `IF NOT EXISTS`) เพื่อกันเคสที่ cron พลาดไปเดือนหนึ่ง
      ⚠️ partition ที่มีข้อมูลแล้วต้องใช้ `CONCURRENTLY` (ส.ค. มี 3.36M แถว — ล็อกไม่ได้)
- [ ] **T011** `backend-connector` — `infrastructure/postgres/indexes.sql`
      อัปเดตคอมเมนต์ให้ชี้มาที่ script ตัวใหม่ แทนคำแนะนำให้รัน DO block ด้วยมือ
- [ ] **T012** `backend-connector` — deploy script ขึ้น VM แทนไฟล์เดิม + รันทดสอบแบบ dry
      (สร้าง partition ต.ค. ล่วงหน้าเลย เพราะยังไงวันที่ 20 ก.ย. ก็ต้องสร้าง)
- [ ] **Checkpoint 3** — query `pg_indexes` บน production ต้องเห็น partition ทุกเดือน
      มี index ครบ 4 ตัวรวม `_id_idx` · รัน script ซ้ำอีกครั้งต้องไม่ error (idempotent)

## Phase 4 — ปิดงาน

- [ ] **T013** `test-runner` — `npm run build` + `npm run lint` ครั้งสุดท้าย
- [ ] **T014** `plan-orchestrator` — commit + push ทั้ง web และ infra repo · รอ CI เขียว
- [ ] **T015** `plan-orchestrator` — ยืนยันบน production: log DLT รอบจริงส่งได้ > 8 คัน
- [ ] **Checkpoint 4** — quote ผลจริงทุกข้อใน Done When ลง `.toh/progress.md`

## หมายเหตุที่ต้องระวัง

- **ห้ามเพิ่มความถี่การส่ง DLT** — spec จำกัด 3 ครั้ง/นาที/IP และเคยโดน 429 มาแล้ว
  (ดู memory `dlt-validation-lesson.md`) แผนนี้เพิ่ม *จำนวนคันต่อรอบ* ไม่ใช่จำนวนรอบ
- **`license` ต้องมีตัวอักษรอย่างน้อย 1 ตัว** — validator เดิมมีอยู่แล้ว ห้ามถอด
- 25 คันที่ตำแหน่งเก่ากว่า 24 ชม. **แก้ด้วยโค้ดไม่ได้** — เป็นปัญหา SIM/ฮาร์ดแวร์ที่หน้างาน
  แผนนี้ทำได้แค่ทำให้พี่โต *มองเห็น* ว่าคันไหน เพื่อไปตามต่อ
- **ห้ามแก้ `displayStatus`** — เคยพลาดตอน `b6db3fb` (การ์ด 20 คันเด้ง `stopped`→`offline`
  เพราะเอา position เก่ามาคิดสถานะ) ต้องคง `livePos` แยกจาก `pos` ไว้เสมอ
- **DLT reject ทั้ง batch ถ้ามี 1 record ผิด** — เพิ่มจาก 8 → 15 คัน = เพิ่มโอกาสเจอ record เสีย
  ตัวใหม่ ต้องรัน `validateDltLocation()` ทุก record ก่อนส่ง และ log `indx` ที่ DLT บอกกลับมา
- ตัวเลข 15 คันวัดตอน ~10:55 น. ช่วงกลางวัน — กลางคืนรถจอดจะน้อยกว่านี้เป็นเรื่องปกติ ไม่ใช่บั๊ก
