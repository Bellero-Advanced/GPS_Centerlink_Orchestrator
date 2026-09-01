-- ═══════════════════════════════════════════════════════
-- Slot Auto-Cleanup System — Bellerox GPS
-- Runs every 5 minutes via pg_cron
-- Releases expired slots + processes queue
-- ═══════════════════════════════════════════════════════

-- ── Enable pg_cron extension ─────────────────────────────

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ── Cleanup function ─────────────────────────────────────

CREATE OR REPLACE FUNCTION cleanup_expired_slots()
RETURNS TABLE(
  released_count INTEGER,
  processed_count INTEGER
) AS $$
DECLARE
  v_released INTEGER := 0;
  v_processed INTEGER := 0;
  v_expired_slot RECORD;
  v_queue_result RECORD;
BEGIN
  -- Find and release all expired reserved slots
  FOR v_expired_slot IN
    SELECT slot_number
    FROM cl_payment_slots
    WHERE status = 'reserved'
      AND expires_at < now()
    FOR UPDATE SKIP LOCKED
  LOOP
    -- Release the expired slot
    PERFORM release_payment_slot(v_expired_slot.slot_number);
    v_released := v_released + 1;

    -- Try to process next in queue
    SELECT * INTO v_queue_result
    FROM process_next_in_queue();

    IF v_queue_result.success THEN
      v_processed := v_processed + 1;
    END IF;
  END LOOP;

  -- Also release paid slots that have been paid for > 5 minutes
  -- (safety buffer to ensure webhook processing completed)
  FOR v_expired_slot IN
    SELECT slot_number
    FROM cl_payment_slots
    WHERE status = 'paid'
      AND paid_at < now() - INTERVAL '5 minutes'
    FOR UPDATE SKIP LOCKED
  LOOP
    -- Release the paid slot
    PERFORM release_payment_slot(v_expired_slot.slot_number);
    v_released := v_released + 1;

    -- Try to process next in queue
    SELECT * INTO v_queue_result
    FROM process_next_in_queue();

    IF v_queue_result.success THEN
      v_processed := v_processed + 1;
    END IF;
  END LOOP;

  RETURN QUERY SELECT v_released, v_processed;
END;
$$ LANGUAGE plpgsql;

-- ── Schedule cron job (every 5 minutes) ──────────────────

-- Note: pg_cron.schedule returns a job ID
-- Job name: 'cleanup-payment-slots'
-- Schedule: */5 * * * * (every 5 minutes)

DO $$
BEGIN
  -- Remove existing job if exists (idempotent)
  PERFORM cron.unschedule('cleanup-payment-slots');
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

SELECT cron.schedule(
  'cleanup-payment-slots',
  '*/5 * * * *',  -- Every 5 minutes
  $$SELECT * FROM cleanup_expired_slots()$$
);

-- ── Manual trigger function (for testing) ────────────────

CREATE OR REPLACE FUNCTION trigger_slot_cleanup()
RETURNS TABLE(
  released_count INTEGER,
  processed_count INTEGER,
  triggered_at TIMESTAMPTZ
) AS $$
DECLARE
  v_result RECORD;
BEGIN
  SELECT * INTO v_result FROM cleanup_expired_slots();

  RETURN QUERY SELECT
    v_result.released_count,
    v_result.processed_count,
    now() AS triggered_at;
END;
$$ LANGUAGE plpgsql;

-- ── Logging table for cleanup history (optional) ─────────

CREATE TABLE IF NOT EXISTS cl_slot_cleanup_log (
  id              BIGSERIAL PRIMARY KEY,
  released_count  INTEGER NOT NULL,
  processed_count INTEGER NOT NULL,
  run_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Keep only last 7 days of logs
CREATE INDEX idx_cleanup_log_run_at ON cl_slot_cleanup_log (run_at DESC);

-- ── Enhanced cleanup with logging ────────────────────────

CREATE OR REPLACE FUNCTION cleanup_expired_slots_with_log()
RETURNS VOID AS $$
DECLARE
  v_result RECORD;
BEGIN
  SELECT * INTO v_result FROM cleanup_expired_slots();

  -- Log the cleanup run
  INSERT INTO cl_slot_cleanup_log (released_count, processed_count)
  VALUES (v_result.released_count, v_result.processed_count);

  -- Cleanup old logs (keep 7 days)
  DELETE FROM cl_slot_cleanup_log
  WHERE run_at < now() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- ── Update cron job to use logging version ───────────────

DO $$
BEGIN
  PERFORM cron.unschedule('cleanup-payment-slots');
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

SELECT cron.schedule(
  'cleanup-payment-slots',
  '*/5 * * * *',
  $$SELECT cleanup_expired_slots_with_log()$$
);

-- ── View cleanup history (admin) ─────────────────────────

CREATE OR REPLACE VIEW v_cleanup_history AS
SELECT
  id,
  released_count,
  processed_count,
  run_at,
  CASE
    WHEN released_count > 0 THEN 'Active cleanup'
    WHEN processed_count > 0 THEN 'Queue processed'
    ELSE 'No action needed'
  END AS status
FROM cl_slot_cleanup_log
ORDER BY run_at DESC
LIMIT 100;

-- ── Grant permissions ────────────────────────────────────

GRANT SELECT ON v_cleanup_history TO authenticated;
GRANT SELECT ON cl_slot_cleanup_log TO authenticated;

-- ══════════════════════════════════════════════════════════
-- Migration Notes:
--
-- 1. pg_cron runs as superuser by default
-- 2. Cron job runs every 5 minutes (*/5 * * * *)
-- 3. Manual trigger: SELECT * FROM trigger_slot_cleanup();
-- 4. View history: SELECT * FROM v_cleanup_history;
-- 5. Check cron jobs: SELECT * FROM cron.job;
-- ══════════════════════════════════════════════════════════
