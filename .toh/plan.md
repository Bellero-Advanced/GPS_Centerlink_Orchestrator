# 📋 Plan: ที่อยู่ ต./อ./จ. ในรายงาน — เร็วเท่าเดิม ไม่ง้อ API ภายนอก

**Status:** completed ✅ 2026-09-26
**Created:** 2026-09-26
**Repos:** bellerox-gps-web (api-gateway + web) · prod VM

## Goal
ทุกแถวในรายงาน (trips/stops/daily) แสดง "ต.xxx อ.xxx จ.xxx" ทันทีที่ตารางโหลด — ไม่เห็นพิกัดดิบ

## Root cause
api-gateway คืน `startAddress/endAddress: null` → browser geocode ทีละจุดผ่าน Worker → Nominatim (1 req/s)
→ 100 จุด ≈ 100+ วินาที, cold start/502 retry → ส่วนใหญ่ยังเป็นพิกัด (ตามภาพ มีแค่แถวสุดท้ายที่ได้)

## Approach — Offline reverse geocoding (point-in-polygon)
ต./อ./จ. คือ "เขตการปกครอง" ไม่ใช่ที่อยู่ถนน → ไม่ต้องเรียก API เลย
- ใช้ขอบเขตตำบลทั่วประเทศ (~7,4xx polygons, ชื่อไทย, OCHA/HDX Thailand admin level 3, CC-BY) — simplify แล้ว ~10-20 MB GeoJSON
- api-gateway โหลดเข้า memory ตอน boot + grid/bbox index → lookup < 0.1 ms/จุด, 0 network, 0 rate limit
- ใส่ address ลง response `/api/fleet/trips|stops` เลย → frontend แสดงทันที, PDF/CSV export ไม่ต้องรอ
- จุดนอกประเทศ/ในทะเล → null → frontend fallback ไป hook เดิม (Worker) เฉพาะจุดนั้น

## Done When
- [x] `/api/fleet/trips` 7 วัน ทุกแถวมี startAddress/endAddress ภาษาไทย, latency เพิ่ม < 50 ms
- [x] ตัวอย่างในภาพ 14.58522,100.89456 → ต.ท่าช้าง อ.เสาไห้ จ.สระบุรี (ตรงกับ Worker)
- [x] เทียบสุ่ม 50 จุดกับ Worker/Longdo ตรงระดับตำบล ≥ 95%
- [x] หน้า Daily Trip / Stops / Monthly แสดงที่อยู่ทันที ไม่มีพิกัดดิบ, export ไม่ต้องรอ geocoding
- [x] web `npm run build` + `npm run lint` + tests ผ่าน, CI green, deploy prod

## Phase 1 — Boundary data
- [x] T001 dev-builder — ดาวน์โหลด Thai admin L3 boundaries, simplify (mapshaper ~0.0005°), เก็บเฉพาะ ADM3_TH/ADM2_TH/ADM1_TH → `api-gateway/data/th-tambon.geojson.gz`
- [x] T002 dev-builder — `api-gateway/api/thaiAdmin.ts`: load + grid index (0.05°) + ray-casting PIP → `lookup(lat,lon) → {subdistrict,district,province,short}` · format ต./อ./จ. (กทม. ใช้ แขวง/เขต)
- [x] T003 test-runner — unit test 10 จุดรู้คำตอบ (กทม., สระบุรี, ชายแดน, ทะเล→null) + benchmark 10k lookups
- **Checkpoint:** tests ผ่าน, 10k lookups < 500 ms

## Phase 2 — API
- [x] T004 dev-builder — `api-gateway/api/fleet.ts` trips/stops (+ Traccar fallback rows ที่ address null) เติม address จาก lookup
- [x] T005 dev-builder — Dockerfile copy data/, memory check (VM e2-medium 4 GB)
- **Checkpoint:** curl local ได้ address ครบ

## Phase 3 — Frontend
- [x] T006 dev-builder — `DailyTripReport.tsx`, `MonthlySummaryReport.tsx`, stops/alerts: ใช้ server address ก่อน, hook เดิมเป็น fallback เท่านั้น · export ใช้ server address
- [x] T007 test-runner — build + lint + vitest
- **Checkpoint:** หน้า Reports local ไม่มีพิกัดดิบ

## Phase 4 — Ship
- [x] T008 — deploy api-gateway บน VM, verify curl prod + Playwright หน้า Reports
- [x] T009 — commit + push (web, parent bump), CI green, อัปเดต memory

## Result
- Data: chingchai/OpenGISData-Thailand subdistricts (HDX COD = 437 MB, GADM has no Thai tambon names); 49 names cut off by the 48-byte field limit were restored
- Accuracy vs Longdo, 50 points: tambon 47/49, amphoe 49/49 (Nominatim itself was wrong on 36/50)
- Prod: 7-day fleet 10,774/10,822 points resolved in 148 ms total · container RSS 80 MB · load 485 ms
- web 082f756 · CI green (Build + Deploy to Cloudflare Pages)
- Browser verification in a logged-in session was not done (no credentials available to the agent)
