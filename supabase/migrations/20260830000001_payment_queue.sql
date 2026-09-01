-- ═══════════════════════════════════════════════════════
-- Payment Queue System — Bellerox GPS
-- FIFO queue for when all 99 slots are occupied
-- Auto-processes when slot becomes available
-- ═══════════════════════════════════════════════════════

-- ── Payment Queue Table ──────────────────────────────────

CREATE TABLE IF NOT EXISTS cl_payment_queue (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id       INTEGER NOT NULL,
  invoice_id      UUID NOT NULL,
  base_amount     NUMERIC(10,2) NOT NULL,
  requested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  notified_at     TIMESTAMPTZ,
  processed_at    TIMESTAMPTZ,
  status          VARCHAR(20) NOT NULL DEFAULT 'waiting',
  slot_number     INTEGER,
  error_message   TEXT,

  CONSTRAINT valid_queue_status CHECK (status IN ('waiting', 'processing', 'completed', 'cancelled', 'failed'))
);

-- Indexes for FIFO processing
CREATE INDEX idx_queue_status_requested ON cl_payment_queue (status, requested_at) WHERE status = 'waiting';
CREATE INDEX idx_queue_device ON cl_payment_queue (device_id);
CREATE INDEX idx_queue_invoice ON cl_payment_queue (invoice_id);

-- ── Helper function: Add to queue ────────────────────────

CREATE OR REPLACE FUNCTION add_to_payment_queue(
  p_device_id INTEGER,
  p_invoice_id UUID,
  p_base_amount NUMERIC
)
RETURNS TABLE(queue_id UUID, position INTEGER) AS $$
DECLARE
  v_queue_id UUID;
  v_position INTEGER;
BEGIN
  -- Insert into queue
  INSERT INTO cl_payment_queue (device_id, invoice_id, base_amount, status)
  VALUES (p_device_id, p_invoice_id, p_base_amount, 'waiting')
  RETURNING id INTO v_queue_id;

  -- Calculate position (1-based)
  SELECT COUNT(*) + 1 INTO v_position
  FROM cl_payment_queue
  WHERE status = 'waiting'
    AND requested_at < (SELECT requested_at FROM cl_payment_queue WHERE id = v_queue_id);

  RETURN QUERY SELECT v_queue_id, v_position;
END;
$$ LANGUAGE plpgsql;

-- ── Helper function: Get queue position ──────────────────

CREATE OR REPLACE FUNCTION get_queue_position(p_queue_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_position INTEGER;
  v_requested_at TIMESTAMPTZ;
BEGIN
  -- Get requested_at for this queue entry
  SELECT requested_at INTO v_requested_at
  FROM cl_payment_queue
  WHERE id = p_queue_id AND status = 'waiting';

  IF v_requested_at IS NULL THEN
    RETURN NULL; -- Not in queue or not waiting
  END IF;

  -- Count entries before this one
  SELECT COUNT(*) + 1 INTO v_position
  FROM cl_payment_queue
  WHERE status = 'waiting'
    AND requested_at < v_requested_at;

  RETURN v_position;
END;
$$ LANGUAGE plpgsql;

-- ── Helper function: Process next in queue ───────────────

CREATE OR REPLACE FUNCTION process_next_in_queue()
RETURNS TABLE(
  queue_id UUID,
  device_id INTEGER,
  invoice_id UUID,
  base_amount NUMERIC,
  slot_number INTEGER,
  success BOOLEAN
) AS $$
DECLARE
  v_next_entry RECORD;
  v_slot_result RECORD;
BEGIN
  -- Get next waiting entry (FIFO)
  SELECT * INTO v_next_entry
  FROM cl_payment_queue
  WHERE status = 'waiting'
  ORDER BY requested_at
  LIMIT 1
  FOR UPDATE SKIP LOCKED;

  IF v_next_entry IS NULL THEN
    -- Queue is empty
    RETURN QUERY SELECT NULL::UUID, NULL::INTEGER, NULL::UUID, NULL::NUMERIC, NULL::INTEGER, false;
    RETURN;
  END IF;

  -- Mark as processing
  UPDATE cl_payment_queue
  SET status = 'processing'
  WHERE id = v_next_entry.id;

  -- Try to reserve a slot
  SELECT * INTO v_slot_result
  FROM reserve_payment_slot(v_next_entry.device_id, v_next_entry.invoice_id);

  IF v_slot_result.slot_number IS NULL THEN
    -- Still no slots available (shouldn't happen)
    UPDATE cl_payment_queue
    SET
      status = 'failed',
      error_message = 'No slots available',
      processed_at = now()
    WHERE id = v_next_entry.id;

    RETURN QUERY SELECT v_next_entry.id, v_next_entry.device_id, v_next_entry.invoice_id, v_next_entry.base_amount, NULL::INTEGER, false;
    RETURN;
  END IF;

  -- Success! Mark as completed
  UPDATE cl_payment_queue
  SET
    status = 'completed',
    slot_number = v_slot_result.slot_number,
    notified_at = now(),
    processed_at = now()
  WHERE id = v_next_entry.id;

  RETURN QUERY SELECT v_next_entry.id, v_next_entry.device_id, v_next_entry.invoice_id, v_next_entry.base_amount, v_slot_result.slot_number, true;
END;
$$ LANGUAGE plpgsql;

-- ── Helper function: Cancel queue entry ──────────────────

CREATE OR REPLACE FUNCTION cancel_queue_entry(p_queue_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  updated_rows INTEGER;
BEGIN
  UPDATE cl_payment_queue
  SET
    status = 'cancelled',
    processed_at = now()
  WHERE id = p_queue_id
    AND status = 'waiting';

  GET DIAGNOSTICS updated_rows = ROW_COUNT;
  RETURN updated_rows > 0;
END;
$$ LANGUAGE plpgsql;

-- ── Stats function ───────────────────────────────────────

CREATE OR REPLACE FUNCTION get_queue_stats()
RETURNS TABLE(
  waiting_count INTEGER,
  processing_count INTEGER,
  avg_wait_seconds NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) FILTER (WHERE status = 'waiting')::INTEGER AS waiting_count,
    COUNT(*) FILTER (WHERE status = 'processing')::INTEGER AS processing_count,
    ROUND(
      AVG(EXTRACT(EPOCH FROM (COALESCE(processed_at, now()) - requested_at)))
      FILTER (WHERE status IN ('completed', 'failed'))
    , 2) AS avg_wait_seconds
  FROM cl_payment_queue
  WHERE requested_at > now() - INTERVAL '1 hour'; -- Last hour stats
END;
$$ LANGUAGE plpgsql;

-- ── Row Level Security ────────────────────────────────────

ALTER TABLE cl_payment_queue ENABLE ROW LEVEL SECURITY;

-- Service role can do everything
CREATE POLICY "service_role_all" ON cl_payment_queue
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Users can only see their own queue entries
CREATE POLICY "users_own_queue" ON cl_payment_queue
  FOR SELECT
  TO authenticated
  USING (device_id IN (
    SELECT id FROM tc_devices WHERE userid = auth.uid()::INTEGER
  ));
