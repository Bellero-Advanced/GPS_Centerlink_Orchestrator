# Plan — Reports Summary Fix + Caching Infrastructure

**Status:** `approved`  
**Created:** 2026-08-20  
**Started:** 2026-08-20  
**Model:** claude-opus-5

---

## 🎯 Goal

แก้ไข Reports System ให้ถูกต้อง + เพิ่ม Performance:

### ปัญหาเร่งด่วน (Phase 1-2):
1. **Summary Metrics ผิด** — PDF แสดงค่าผิด:
   - ระยะทางรวม: 1689.1 กม. (ผิด) → ควรเป็น 168.7 กม. (ระยะสะสมสุดท้าย)
   - ความเร็วเฉลี่ย: 0 km/h → ควรเฉลี่ยจากทุกเที่ยว
   - เวลาเครื่องยนต์ทำงาน: 0.0 ชม. → ควรรวม duration ทุกเที่ยว
   - เวลาจอด: หายไป → ควรมี (idle + stopped)
   - เวลาจอดติดเครื่อง: 0.0 ชม. → ควรคำนวณจาก idle status

2. **แก้ `calculateComprehensiveSummary()`** ให้คำนวณถูกทุก metric

### Performance & Scalability (Phase 3-5):
3. **Query ช้า** — ตอนนี้ query Traccar API ทุกครั้ง (20k vehicles × 7 days = ล้าน positions)
4. **ต้องการ Caching Layer:**
   - PostgreSQL Materialized View เก็บรายงานสำเร็จรูป
   - Background Worker คำนวณทุก 5-10 นาที
   - Pre-geocoding ทุก position ทันที (ไม่ต้องรอตอน query)
   - Redis Cache เก็บ 30 วันล่าสุด
   - Query เร็ว < 50ms

---

## 📦 Stack

**Phase 1-2 (Fix Metrics):**
- React 18 + TypeScript strict
- `reportSummary.ts` — calculation logic
- Traccar API data structure

**Phase 3-5 (Caching Infrastructure):**
- PostgreSQL 16 (Materialized Views)
- Node.js Background Worker (Bull Queue)
- Redis 7 (cache layer)
- Longdo Map API (geocoding)
- Docker Compose (worker deployment)

---

## 📄 Files Affected

**Phase 1-2:**
- `src/lib/reportSummary.ts` — แก้ calculation
- `src/hooks/useDailyTripReport.ts` — เช็คว่าส่งข้อมูลครบไหม
- `src/components/reports/DailyTripReport.tsx` — ตรวจสอบ PDF export

**Phase 3-5:**
- `infrastructure/workers/report-processor/` — Background worker (new)
- `infrastructure/postgres/schema-reports.sql` — Materialized views (new)
- `infrastructure/docker/docker-compose.workers.yml` — Worker deployment (new)
- `bellerox-gps-web/src/hooks/useReportCache.ts` — Hook ใช้ cache (new)

---

## ✅ Done When

**Phase 1-2 (Fix Summary):**
- [ ] ระยะทางรวม = ระยะสะสมสุดท้าย (168.7 กม. ไม่ใช่ 1689.1)
- [ ] ความเร็วเฉลี่ย = average speed จากทุกเที่ยว
- [ ] เวลาเครื่องยนต์ทำงาน = sum(duration) จากทุกเที่ยว
- [ ] เวลาจอด = sum(stopped time)
- [ ] เวลาจอดติดเครื่อง = sum(idle time)
- [ ] ใช้น้ำมันทั้งหมด = sum(fuel) จากทุกเที่ยว
- [ ] PDF export แสดงค่าถูกต้อง (ทดสอบกับรถเดียวกัน)

**Phase 3-5 (Caching):**
- [ ] Materialized view `daily_trip_reports` สร้างเสร็จ
- [ ] Background worker คำนวณรายงานทุก 10 นาที
- [ ] Geocoding pipeline ทำงาน (pre-cache addresses)
- [ ] Redis cache เก็บ 30 วันล่าสุด
- [ ] Hook `useReportCache` ดึงจาก cache ก่อน fallback Traccar
- [ ] Query เร็ว < 100ms (test กับ 7 days, 1 vehicle)
- [ ] Worker deploy ด้วย Docker Compose

---

## 📋 Phases

### Phase 1 — Investigation (ตรวจสอบ Bug)

**Duration:** ~15 min  
**Agent:** dev-builder

- [ ] **T001** อ่าน `reportSummary.ts` เช็คว่า `calculateComprehensiveSummary()` คำนวณยังไง
  - Files: `src/lib/reportSummary.ts`
  - Goal: หา logic ที่ทำให้ totalDistance = 1689.1 แทน 168.7

- [ ] **T002** อ่าน `useDailyTripReport.ts` เช็คว่า data structure ที่ส่งเข้า summary ถูกต้องไหม
  - Files: `src/hooks/useDailyTripReport.ts`
  - Goal: เช็ค field `distance`, `duration`, `avgSpeed` ส่งเข้ามาครบไหม

- [ ] **T003** เช็คว่า Traccar API ส่ง field อะไรมาบ้าง
  - Files: `src/services/traccarService.ts`, `src/types/traccar.types.ts`
  - Goal: ยืนยันว่า `spentFuel`, `duration`, `averageSpeed` มีใน TripReport

**Checkpoint 1:** รู้สาเหตุว่าทำไม metrics ผิด

---

### Phase 2 — Fix Summary Calculation (แก้ Metrics)

**Duration:** ~45 min  
**Agent:** dev-builder

- [ ] **T004** แก้ `totalDistance` ให้ใช้ระยะสะสมสุดท้าย
  - Files: `src/lib/reportSummary.ts`
  - Change: `totalDistance = data[data.length - 1].totalDistance` หรือ `sum(distance per trip)`

- [ ] **T005** แก้ `avgSpeed` ให้เฉลี่ยจากทุกเที่ยว
  - Files: `src/lib/reportSummary.ts`
  - Change: `avgSpeed = sum(distance) / sum(duration in hours)`

- [ ] **T006** แก้ `totalEngineHours` ให้รวม duration จากทุกเที่ยว
  - Files: `src/lib/reportSummary.ts`
  - Change: `totalEngineHours = sum(duration in hours)`

- [ ] **T007** เพิ่ม `totalStoppedTime` คำนวณจาก stopped positions
  - Files: `src/lib/reportSummary.ts`
  - Change: ต้องดึงข้อมูล stopped events หรือคำนวณจาก speed = 0 positions

- [ ] **T008** แก้ `totalIdleTime` คำนวณจาก idle positions
  - Files: `src/lib/reportSummary.ts`
  - Change: ดึงจาก events หรือ positions ที่ speed = 0 + ignition ON

- [ ] **T009** แก้ `totalFuel` รวมจากทุกเที่ยว
  - Files: `src/lib/reportSummary.ts`
  - Change: `totalFuel = sum(trip.spentFuel)`

- [ ] **T010** ทดสอบ export PDF กับรถเดิม (2ฒฌ-3550) เช็คค่าตรง 168.7 กม.
  - Goal: ยืนยันว่า PDF แสดงค่าถูกต้อง

**Checkpoint 2:** Summary metrics แสดงถูกต้องทั้งหมด

---

### Phase 3 — Database Schema (Materialized View)

**Duration:** ~1 hr  
**Agent:** dev-builder

- [ ] **T011** สร้าง schema `daily_trip_reports` table
  - Files: `infrastructure/postgres/schema-reports.sql` (new)
  - Schema:
    ```sql
    CREATE TABLE daily_trip_reports (
      id SERIAL PRIMARY KEY,
      device_id INT NOT NULL,
      report_date DATE NOT NULL,
      trip_count INT,
      total_distance DECIMAL(10,2),
      total_duration INT, -- minutes
      avg_speed DECIMAL(5,2),
      max_speed DECIMAL(5,2),
      total_fuel DECIMAL(10,2),
      stopped_time INT, -- minutes
      idle_time INT, -- minutes
      trips JSONB, -- array of trip details with geocoded addresses
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(device_id, report_date)
    );
    CREATE INDEX idx_daily_reports_device_date ON daily_trip_reports(device_id, report_date);
    ```

- [ ] **T012** สร้าง `geocode_cache` table
  - Files: `infrastructure/postgres/schema-reports.sql`
  - Schema:
    ```sql
    CREATE TABLE geocode_cache (
      id SERIAL PRIMARY KEY,
      lat DECIMAL(10,6),
      lng DECIMAL(10,6),
      address TEXT,
      provider VARCHAR(50), -- 'longdo', 'nominatim'
      created_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(lat, lng)
    );
    CREATE INDEX idx_geocode_latlon ON geocode_cache(lat, lng);
    ```

**Checkpoint 3:** Database schema พร้อมใช้

---

### Phase 4 — Background Worker (Report Processor)

**Duration:** ~2 hrs  
**Agent:** dev-builder

- [ ] **T013** สร้าง Node.js worker project
  - Files: `infrastructure/workers/report-processor/package.json` (new)
  - Dependencies: `bull`, `ioredis`, `pg`, `axios`, `date-fns`

- [ ] **T014** สร้าง `ReportJob` — คำนวณรายงานรายวัน
  - Files: `infrastructure/workers/report-processor/src/jobs/dailyReportJob.ts` (new)
  - Logic:
    1. Query Traccar `/api/reports/trips?deviceId=X&from=Y&to=Z`
    2. คำนวณ summary metrics (ใช้ logic เดียวกับ `reportSummary.ts`)
    3. Geocode start/end positions (query geocode_cache ก่อน, ไม่เจอค่อยเรียก Longdo)
    4. Upsert ลง `daily_trip_reports`

- [ ] **T015** สร้าง `GeocodingJob` — pre-geocode positions
  - Files: `infrastructure/workers/report-processor/src/jobs/geocodingJob.ts` (new)
  - Logic:
    1. Listen Traccar WebSocket สำหรับ new positions
    2. Batch geocode ทุก 30 วิ (100 positions/batch)
    3. Insert ลง `geocode_cache`

- [ ] **T016** สร้าง `worker.ts` — main entry point
  - Files: `infrastructure/workers/report-processor/src/worker.ts` (new)
  - Logic:
    - Queue: `dailyReportQueue` — run ทุกวัน 00:30 (สำหรับเมื่อวาน)
    - Queue: `geocodingQueue` — run real-time

**Checkpoint 4:** Worker คำนวณรายงานได้

---

### Phase 5 — Redis Cache + Hook Integration

**Duration:** ~1 hr  
**Agent:** dev-builder

- [ ] **T017** สร้าง `useReportCache` hook
  - Files: `src/hooks/useReportCache.ts` (new)
  - Logic:
    1. Check Redis cache: `reports:daily:{deviceId}:{date}`
    2. ถ้าไม่เจอ → query `daily_trip_reports` table (via Supabase)
    3. ถ้ายังไม่เจอ (รายงานยังไม่ถูกสร้าง) → fallback Traccar API
    4. Cache result ใน Redis (TTL 7 days)

- [ ] **T018** เปลี่ยน `useDailyTripReport` ให้ใช้ cache
  - Files: `src/hooks/useDailyTripReport.ts`
  - Change: เรียก `useReportCache` ก่อน fallback Traccar

- [ ] **T019** สร้าง Docker Compose config สำหรับ worker
  - Files: `infrastructure/docker/docker-compose.workers.yml` (new)
  - Services:
    - `report-processor` — Node.js worker
    - `redis` — Bull queue backend
    - Share network กับ `traccar` + `postgres`

**Checkpoint 5:** Cache ทำงาน + query เร็ว < 100ms

---

### Phase 6 — Testing & Deployment

**Duration:** ~30 min  
**Agent:** test-runner

- [ ] **T020** ทดสอบ summary metrics (Phase 2)
  - Test: Export PDF รถ 2ฒฌ-3550 วันที่ 19/08/2569
  - Expected: ระยะทางรวม 168.7 กม., ความเร็วเฉลี่ย > 0, เวลาเครื่องยนต์ > 0

- [ ] **T021** ทดสอบ worker คำนวณรายงาน
  - Test: Trigger `dailyReportJob` manual
  - Expected: Insert ลง `daily_trip_reports` สำเร็จ

- [ ] **T022** ทดสอบ geocoding cache
  - Test: Query `geocode_cache` table
  - Expected: มี addresses cached > 1000 rows

- [ ] **T023** ทดสอบ query speed
  - Test: Query รายงาน 7 วัน ของ 1 รถ
  - Expected: Response time < 100ms (จาก cache)

- [ ] **T024** Build + Deploy
  - Commands:
    - `npm run build` (web app)
    - `cd infrastructure/workers/report-processor && npm run build`
    - `docker-compose -f docker-compose.workers.yml up -d`

**Checkpoint 6:** ทุกอย่างทำงาน + deploy production

---

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ User Request: รายงานรายวัน วันที่ 19/08/2569                    │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
                  ┌─────────────────────┐
                  │ useReportCache Hook │
                  └──────────┬──────────┘
                             │
              ┌──────────────┴───────────────┐
              │                              │
              ▼                              ▼
    ┌─────────────────┐          ┌──────────────────────┐
    │ Redis Cache     │ MISS     │ PostgreSQL           │
    │ TTL: 7 days     │────────▶ │ daily_trip_reports   │
    └─────────────────┘          └──────────┬───────────┘
              │ HIT                          │ MISS
              │                              │
              ▼                              ▼
       ┌─────────────┐              ┌──────────────────┐
       │ Return JSON │              │ Traccar API      │
       │ < 10ms      │              │ (fallback)       │
       └─────────────┘              └──────────────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ Calculate +     │
                                    │ Cache result    │
                                    └─────────────────┘

═══════════════════════════════════════════════════════════════════

Background Worker (runs every 10 minutes):

┌────────────────────────────────────────────────────────────────┐
│ Bull Queue Scheduler                                           │
│ Cron: */10 * * * * (every 10 min)                             │
└───────────────────────────┬────────────────────────────────────┘
                            │
                            ▼
                  ┌─────────────────────┐
                  │ dailyReportJob      │
                  │ 1. Query Traccar    │
                  │ 2. Calculate        │
                  │ 3. Geocode          │
                  │ 4. Upsert DB        │
                  └──────────┬──────────┘
                             │
              ┌──────────────┴───────────────┐
              │                              │
              ▼                              ▼
    ┌──────────────────┐          ┌──────────────────┐
    │ geocode_cache    │          │ daily_trip_      │
    │ (check first)    │          │ reports (upsert) │
    └──────────────────┘          └──────────────────┘
              │ MISS
              │
              ▼
    ┌──────────────────┐
    │ Longdo Map API   │
    │ Geocode + cache  │
    └──────────────────┘
```

---

## 🔢 Performance Estimates

### ก่อนแก้ (ตอนนี้):
- Query 7 วัน, 1 รถ: **8-15 วิ** (Traccar API + frontend geocoding)
- Query 7 วัน, 100 รถ: **timeout** (> 60 วิ)

### หลังแก้ (Phase 5):
- Query 7 วัน, 1 รถ: **< 50ms** (Redis cache)
- Query 7 วัน, 100 รถ: **< 500ms** (Redis cache)
- Cold query (cache miss): **< 2 วิ** (PostgreSQL materialized view)

---

## 💰 Infrastructure Cost

| Resource | Config | Monthly Cost |
|----------|--------|--------------|
| Worker VM | e2-micro (GCP) | ~$7 |
| Redis | 512MB Memorystore | ~$25 |
| PostgreSQL storage | +50GB (reports table) | ~$5 |
| Longdo API | 10k geocoding/day | ฿1,500 |
| **Total** | | **~฿1,200 (~$35)** |

Revenue: 20,000 vehicles × ฿35 = ฿700,000/month → cost 0.17% ✅

---

## ⚠️ Risk Assessment

- **Medium risk:** Worker crash → รายงานไม่อัพเดท (mitigation: health check + auto-restart)
- **Low risk:** Redis down → fallback PostgreSQL (slower แต่ยังใช้ได้)
- **Low risk:** Geocoding quota limit → fallback Nominatim (ฟรี แต่ช้ากว่า)

---

## 📝 Notes

- Phase 1-2 (Fix Metrics) ต้องทำเสร็จก่อน ไม่งั้นผู้ใช้เห็นเลขผิดต่อ
- Phase 3-5 (Caching) ทำทีหลังได้ แต่จะช่วย performance มาก
- Worker ควร run บน VM แยก (ไม่ใช่ Traccar VM) เพื่อไม่กระทบ Traccar performance
- Geocoding cache จะเติบโตเรื่อยๆ → ควรมี retention policy (เก็บ 1 ปี)

---

**Estimated Total Time:** ~6-8 hours (Phase 1-2: 1 hr, Phase 3-5: 4-5 hrs, Testing: 1 hr)

**Ready for review.** พิมพ์ **"Go"** เพื่อเริ่มทำงานทั้งแผน
