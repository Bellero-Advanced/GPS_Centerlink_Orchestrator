# Plan: Server-side Address Cache (Geocoding → CF Worker + KV)

Status: approved
Created: 2026-08-25 by /toh-plan
Supersedes: plan-2026-08-22-cost-pipeline-reports-PARKED.md (30 done / 63 pending — parked, restorable from .toh/memory/archive/)

## Goal

ที่อยู่ไทยบน Vehicle Card ต้องขึ้น **ทันที** ไม่ใช่ทยอยขึ้นทีละคัน วันนี้เบราว์เซอร์ geocode เองผ่านคิว
1 request/1.1 วินาที → รถ 214 คันใช้เวลา ~3.9 นาทีจึงจะขึ้นครบ และ Photon (ตัวหลัก) **ต่อไม่ได้เลย**
(HTTP 000 / exit 7 ทุกครั้ง) จึงตกไป Nominatim ที่ช้าและ rate-limit ทุกคัน

ย้าย geocoding ไปฝั่ง server: เพิ่ม `/geocode` ใน Cloudflare Worker ที่ deploy อยู่แล้ว
(`api.centerlink.co.th`) + Workers KV เป็น cache ถาวรร่วมกันทุกผู้ใช้ ใช้ Longdo API
(key มีอยู่แล้ว จ่ายแล้ว ยังไม่ได้ใช้เลย — วัดจริง ~80ms ไม่มี rate limit และคืน ต./อ./จ. ตรงฟอร์แมต)

ผลที่ต้องได้: cache hit ตอบ ~10ms · ผู้ใช้คนที่ 2 ไม่ต้อง geocode ซ้ำ · เลิกคิว 1 วิ/คันในเบราว์เซอร์

## Stack

- Cloudflare Worker (`infrastructure/cloudflare/workers/traccar-proxy.ts`) — เพิ่ม route ไม่สร้าง worker ใหม่
- Workers KV namespace `GEOCODE_CACHE` — free tier 100k reads/วัน
- Longdo Map API `api.longdo.com/map/services/address` — key เก็บเป็น wrangler secret (ห้าม hardcode)
- Web: `bellerox-gps-web/src/hooks/useReverseGeocode.ts` — เรียก `/geocode` แทน Photon/Nominatim
- IndexedDB cache ฝั่ง browser คงไว้ (ลด request ซ้ำข้าม session)

## Done When

- [ ] `npm run build` ใน bellerox-gps-web exit 0 + `npx tsc --noEmit` ไม่มี error
- [ ] `curl "$WORKER/geocode?lat=14.12336&lon=100.50570"` คืน JSON ที่มี short = "ต.โคกช้าง อ.บางไทร จ.พระนครศรีอยุธยา"
- [ ] ยิงซ้ำพิกัดเดิม → response header `x-cache: HIT` และเร็วกว่าครั้งแรก
- [ ] `useReverseGeocode.ts` ไม่มีการเรียก photon.komoot.io / nominatim.openstreetmap.org เหลืออยู่
- [ ] Longdo key ไม่ปรากฏใน `git grep` และไม่อยู่ใน bundle ที่ deploy (`dist/`)
- [ ] CI run เขียว + live bundle มีโค้ดใหม่จริง (ตรวจแบบเดียวกับ commit b6db3fb)

## Phase 1 — Worker endpoint + KV

- [ ] T001 dev-builder — เพิ่ม KV binding GEOCODE_CACHE + Longdo secret ใน infrastructure/cloudflare/wrangler.toml
- [ ] T002 dev-builder — เพิ่ม /geocode handler (KV get → miss → Longdo → KV put, key = lat/lng 4 ตำแหน่ง) ใน infrastructure/cloudflare/workers/traccar-proxy.ts
- [ ] T003 dev-builder — CORS: ใส่ gpsthailand.centerlink.co.th ใน ALLOWED_ORIGINS ใน infrastructure/cloudflare/workers/traccar-proxy.ts
**Checkpoint:** `npx tsc --noEmit` บน worker ผ่าน AND อ่านโค้ดยืนยัน KV miss → Longdo → KV put ครบวงจร และไม่มี key ใน source

## Phase 2 — Deploy worker + พิสูจน์ endpoint

- [ ] T004 dev-builder — สร้าง KV namespace + ใส่ Longdo secret + deploy worker (ต้อง Node >= 22; ถ้าไม่ได้ → BLOCKED พร้อมคำสั่งให้พี่โตรันเอง)
- [ ] T005 dev-builder — ทดสอบ endpoint จริง: cold call, warm call (x-cache HIT), พิกัดนอกไทย, พิกัดพัง (lat=999) ต้องไม่ 500
**Checkpoint:** `curl "https://api.centerlink.co.th/geocode?lat=14.12336&lon=100.50570"` คืน short ถูก AND ยิงซ้ำได้ `x-cache: HIT`

## Phase 3 — ต่อฝั่งเว็บ + ship

- [ ] T006 dev-builder — เขียน useReverseGeocode.ts ใหม่: เรียก /geocode (คง IndexedDB + in-flight dedup + in-memory CACHE), ตัดคิว 1.1 วิ + Photon/Nominatim ใน bellerox-gps-web/src/hooks/useReverseGeocode.ts
- [ ] T007 dev-builder — ตรวจ call site อื่นที่ใช้ geocode (getCachedGeocode ใน export/report path) ว่าไม่พัง ใน bellerox-gps-web/src
- [ ] T008 test-runner — build + lint + commit + push + เฝ้า CI + ยืนยันโค้ดอยู่บน live bundle
**Checkpoint:** `npm run build` exit 0 AND `npm run lint` ไม่เพิ่ม warning ใหม่ AND CI run conclusion = success

## Notes / Risks

- **Longdo quota:** free tier มีลิมิตต่อวัน — KV cache ทำให้พิกัดซ้ำไม่ยิงใหม่ ถ้าชนลิมิตให้ fallback Nominatim ฝั่ง worker (ไม่ใช่ฝั่ง browser)
- **ห้าม** ใส่ Longdo key ใน frontend/`VITE_*` ที่ bundle ติดไปกับ dist — ต้องอยู่ใน worker secret เท่านั้น
- `position.address` จาก Traccar เป็น null ทั้ง 40/40 (ยืนยันแล้ว) — endpoint นี้เป็นแหล่งเดียวของที่อยู่ไทย
- KV eventual consistency (~60s ข้าม region) ไม่กระทบ เพราะ address ของพิกัดเดิมไม่เปลี่ยน
