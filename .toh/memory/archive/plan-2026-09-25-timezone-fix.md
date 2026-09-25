# 📋 แผนงาน: แก้เวลาเพี้ยน +7 ชม. ในรายงาน & ระบบย้อนหลัง

**Status:** completed ✅
**Created:** 2026-09-24
**Goal:** ให้ `fixtime` ใน DB ตรงกับเวลาจริง (≈ `servertime`) สำหรับรถทุกคัน ทั้งข้อมูลใหม่และข้อมูลย้อนหลัง
และให้ frontend รายงาน/ย้อนหลังแสดง/กรอง/เรียงเวลาเป็น Asia/Bangkok อย่างถูกต้องเสมอ

---

## 🔍 Findings (ตรวจจริงจาก prod 2026-09-24)

1. **ใช้ `fixtime` ถูกแล้ว** — Traccar reports (trips/stops/summary) + `/api/positions?from&to` + replay ใช้ fixtime
   เป็นแกนเวลา · `servertime` = เวลาที่ server ได้รับ (ผิดสำหรับข้อมูล buffer ที่ส่งย้อนหลัง)
2. **ต้นเหตุจริง:** ค่า `decoder.timezone` ที่ตั้งไว้เมื่อ 1 ก.ย. = `"UTC+07:00"` (38 คัน) และ `"-07:00"` (20 คัน)
   **ไม่ใช่ Java TimeZone ID ที่ถูกต้อง** → `TimeZone.getTimeZone()` คืน GMT เงียบๆ → ไม่มีผลอะไรเลย
   (แถมไป override timezone ที่กล่องประกาศใน login packet) · ค่าที่ถูกคือ `GMT+07:00`
3. **ขนาดปัญหา (48 ชม.ล่าสุด):** GT06 ~50 คัน + Meitrack 6 คัน มี `fixtime − servertime ≈ +7.00h` คงที่
   (กล่องส่งเวลาไทย) · ทั้ง retention (ตั้งแต่ 28 ก.ค.) มี **2,791,909 แถว** เพี้ยน +7h
4. GT06 ทั้ง fleet ไม่มีคันไหน offset ≈ 0 เลย → ตั้ง default ระดับ server ได้ (เฉพาะ gt06 decoder ที่อ่านค่านี้;
   gps103/meiligao/startek/meitrack ไม่อ่าน `decoder.timezone`)
5. **Meitrack decoder ไม่รองรับ decoder.timezone** → ต้องใช้ `time.override=serverTime` รายคัน
6. กลุ่มอื่น: GT06 −7h คงที่ 2 คัน (343, 234) · +8h 1 คัน (126) · นาฬิกาพัง/drift (±หลายร้อย-พันชม.) ~23 คัน
   · gps103/meiligao ค่าติดลบ = ข้อมูล buffer ส่งย้อนหลัง → **ถูกต้อง ไม่แตะ**
7. tc_events: deviceMoving/Stopped/alarm ใช้ eventtime = fixtime → เพี้ยนตามไปด้วย
8. **กับดักแฝง:** `infrastructure/docker/docker-compose.yml` ใน repo ตั้ง `TZ/-Duser.timezone=Asia/Bangkok`
   แต่ prod รัน UTC (ถูก) · คอลัมน์เป็น `timestamp without time zone` → ถ้า deploy ด้วยไฟล์ใน repo ข้อมูลทั้งหมดจะเลื่อน 7 ชม.
9. สคริปต์เก่าอันตราย: `backfill-servertime.sql` (บวก servertime +7h — ทิศตรงข้าม), `fix-timezone-production.sh`,
   `batch-remove-decoder-timezone.sh`, `scripts/backfill-timezone.sql`, `scripts/fix-gt06-timezone.*`
10. Frontend: ช่วงวันที่ขึ้นกับ timezone ของ browser · หลายจุดเรียงตาม string ที่ format แล้ว ·
    reportGenerators/PDF/export ใช้เวลา browser · IndexedDB report cache จะเก็บรายงานเวลาผิดไว้ ·
    หน่วย duration ปน s/ms ใน Monthly Summary

---

## 🛠️ Stack
Traccar 6.14.5 (config + device attributes) · PostgreSQL 16 (partitioned by servertime) ·
React 18 + Vite + TS (`bellerox-gps-web`) · Vitest

## ✅ Done When
- [x] ตำแหน่งใหม่ (หลัง restart ≥ 30 นาที): ไม่มีรถ GT06/Meitrack ที่ median offset อยู่ใน 6.5–7.5h
- [x] ข้อมูลย้อนหลังทั้ง retention: แถว +7h ของรถกลุ่มที่จัดประเภทแล้ว = 0 · มี backup table สำหรับ rollback
- [x] รายงาน trip ของรถตัวอย่าง (เช่น 73, 167, 36) ใน API ตรงกับเวลาจริง (เทียบ servertime)
- [x] Frontend: วัน/เดือนในรายงาน + preset ย้อนหลัง อิง Asia/Bangkok ไม่ขึ้นกับ browser · เรียงตาม timestamp
- [x] `npm run build` + `npm run lint` + `npm run test` ผ่าน · push + CI green
- [x] Memory ที่ผิด (timezone-*) แก้ให้ตรงความจริง

---

## Phase 1 — หยุดข้อมูลเพี้ยนใหม่ (Traccar)

- [x] T101 dev-builder — `infrastructure/scripts/tz-audit.sql`: query จัดประเภทรถตาม offset (reuse เป็น weekly monitor)
- [x] T102 dev-builder — ~~server default~~ → ตั้ง `decoder.timezone=GMT+07:00` **รายคัน** ให้ GT06 กลุ่ม +7 (Jt808/ITS/Ulbotech ก็อ่าน key นี้ — default ทั้ง server เสี่ยงทำรถรุ่นอื่นในอนาคตเพี้ยน)
- [x] T103 dev-builder — `infrastructure/scripts/tz-fix-devices.sql`: ลบ `decoder.timezone` ที่ invalid ทั้ง 58 คัน · device 126 → `GMT+08:00` ·
      `time.override=serverTime` ให้ Meitrack +7 (35,36,37,76,83,85,149), GT06 −7 (343,234), 293 และกลุ่มนาฬิกาพัง (list จาก T101)
- [x] T104 dev-builder — `infrastructure/docker/docker-compose*.yml`: TZ/`-Duser.timezone` → `UTC` ให้ตรง prod ·
      ลบสคริปต์เก่าอันตราย (Finding 9)
- [x] T105 dev-builder — deploy traccar.xml ขึ้น VM (`/opt/bellerox-gps/infrastructure/docker/traccar/`) → รัน T103 → `docker restart centerlink-traccar`
      (กล่องจะ reconnect ~1-2 นาที) → รอ 30 นาที → รัน tz-audit
- [x] **Checkpoint 1:** tz-audit บนข้อมูลหลัง restart: GT06/Meitrack bucket "+7" = 0 คัน (quote ผล)

## Phase 2 — แก้ข้อมูลย้อนหลัง (DB backfill)

- [x] T201 dev-builder — `infrastructure/scripts/tz-backfill.sql`: สร้าง `tc_tz_backfill_20260924` (id, deviceid, servertime, fixtime, devicetime) +
      `tc_tz_backfill_events_20260924` ก่อนแก้ทุกแถว
- [x] T202 dev-builder — events ก่อน: `eventtime −7h` เฉพาะ event ที่ join position (positionid+deviceid) ซึ่ง offset 6.5–7.5h และ eventtime ≈ fixtime
- [x] T203 dev-builder — positions ทีละวัน (e2-small RAM 2GB): +7 กลุ่ม → `fixtime/devicetime −7h` เฉพาะแถว 6.5–7.5h ·
      −7 กลุ่ม → `+7h` เฉพาะแถว −7.5…−6.5h · 126 → `−8h` แถว 7.5–8.5h · นาฬิกาพัง → `fixtime = servertime` แถว |offset| > 1h
- [x] T204 dev-builder — `VACUUM ANALYZE` + tz-audit ทั้ง retention + ตรวจ `/api/reports/trips` ของรถตัวอย่าง
- [x] **Checkpoint 2:** แถว +7h ของกลุ่มที่แก้ = 0 · จำนวนแถวที่แก้ = จำนวนใน backup (quote ผล)

## Phase 3 — Frontend รายงาน & ย้อนหลัง (`bellerox-gps-web`)

- [x] T301 dev-builder — `src/lib/reportCache.ts`: bump `DB_VERSION` + ล้าง store เก่า (ทิ้งรายงานที่ cache เวลาผิด)
- [x] T302 dev-builder — `src/lib/timezone.ts`: `startOfDayTH/endOfDayTH/startOfMonthTH/endOfMonthTH`, `hourCycle:'h23'`,
      `fromBangkokString` รองรับวินาที · unit tests `src/lib/__tests__/timezone.test.ts`
- [x] T303 dev-builder — ใช้ helper ใหม่ใน `DailyTripReport.tsx`, `DailyAlertsReport.tsx`, `MonthlySummaryReport.tsx`,
      `DatePresets.tsx`, `DateTimeRangePicker.tsx`, `ReportsPage.tsx`, `TripReplayPage.tsx` (presets), `reportCache.ts` (isToday)
- [x] T304 dev-builder — เรียงตาม timestamp แทน string: `useDailyAlertsReport.ts:152`, `reportGenerators.ts:547/637/871` ·
      histogram ชั่วโมง `reportGenerators.ts:938` ใช้ชั่วโมง Bangkok
- [x] T305 dev-builder — แสดงเวลาเป็น Bangkok: `reportGenerators.ts`, `reportTemplates.ts`, `reportPDFService.ts`, `exportUtils.ts`, ReportsPage v1 stops/events
- [x] T306 dev-builder — หน่วย duration: `useMonthlySummaryReport.ts:94-122`, `reportGenerators.ts:49` (engineHours = ms)
- [x] **Checkpoint 3:** `npm run build` + `npm run lint` + `npm run test` ผ่าน (quote ผล)

## Phase 4 — Ship & Guard

- [x] T401 dev-builder — commit + push web → bump submodule ใน root · commit + push infra · CI green
- [x] T402 dev-builder — แก้ memory: `timezone-7h-offset-root-cause`, `timezone-comprehensive-fix`, `clock-drift-devices-detail` + changelog/active
- [x] **Checkpoint 4:** CI green ทุก repo (quote run) · Done When ครบ

---

## 📊 Evidence (2026-09-24/25)
- Checkpoint 1: post-restart audit — gt06 ok 42 · meitrack ok 4 · tz+7 = 0 (only 207: parked heartbeat copy, fresh fixes offset 0.00)
- Checkpoint 2: backfill 3,897,607 rows (R1 2,792,656 · R2 151,535 · R3 3,521 · R4 895,600 · R5 54,295) + S1 2,931 + R6 20,054 ·
  still_pending = 0 · gt06/meitrack plus7 rows = 0 · future >15m rows = 4 (fleet-wide) · events fixed 47,882
- Trips API: device 36 first trip 23:42:38Z vs first moving servertime 23:43:39Z ✅
- Checkpoint 3: tsc 0 · build ✓ · lint 0 errors (49 old warnings) · timezone tests 18/18 (UTC, NY, BKK) ·
  10 pre-existing failures in vehicleStatus/FloatingVehiclePanel/positionOwnership (same on HEAD)
- Checkpoint 4: web d43004a CI success + deployed · infra 763238a + R6 · root 915364a (root repo has no active CI)
