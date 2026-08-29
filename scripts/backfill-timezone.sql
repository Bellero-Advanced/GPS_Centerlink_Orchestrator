-- ═══════════════════════════════════════════════════════
-- Backfill Timezone Fix — GT06 + Meitrack devices
-- แก้เวลาผิด +7 ชม. ในข้อมูลเก่า
-- ═══════════════════════════════════════════════════════

-- ⚠️ CRITICAL: Backup ก่อนรัน!
-- pg_dump traccar -t tc_positions -t tc_events > backup-before-backfill.sql

BEGIN;

-- 1. แก้ tc_positions (74,816 rows)
-- ID range: 3260680 ถึง 3335495
-- เฉพาะที่ offset +7.00 ชม. (fixtime - servertime ≈ 7 hours)

UPDATE tc_positions
SET
  fixtime = fixtime - INTERVAL '7 hours',
  devicetime = devicetime - INTERVAL '7 hours'
WHERE
  id BETWEEN 3260680 AND 3335495
  AND EXTRACT(EPOCH FROM (fixtime - servertime)) / 3600 BETWEEN 6.5 AND 7.5;

-- 2. แก้ tc_events (2,701 rows)
-- ใช้ช่วงเวลาเดียวกัน

UPDATE tc_events
SET
  eventtime = eventtime - INTERVAL '7 hours'
WHERE
  eventtime >= '2026-08-01 00:00:00+00'
  AND eventtime <= '2026-08-25 00:00:00+00'
  AND EXTRACT(EPOCH FROM (eventtime - servertime)) / 3600 BETWEEN 6.5 AND 7.5;

-- 3. ตรวจสอบผลลัพธ์
SELECT
  'tc_positions' AS table_name,
  COUNT(*) AS updated_rows,
  MIN(fixtime) AS earliest_fix,
  MAX(fixtime) AS latest_fix
FROM tc_positions
WHERE id BETWEEN 3260680 AND 3335495;

SELECT
  'tc_events' AS table_name,
  COUNT(*) AS updated_rows
FROM tc_events
WHERE
  eventtime >= '2026-08-01 00:00:00+00'
  AND eventtime <= '2026-08-25 00:00:00+00';

-- ⚠️ ถ้าผลลัพธ์ถูกต้อง → COMMIT
-- ถ้าผิด → ROLLBACK

-- COMMIT;
-- ROLLBACK;

-- 4. Vacuum หลัง commit (รันแยก)
-- VACUUM ANALYZE tc_positions;
-- VACUUM ANALYZE tc_events;
