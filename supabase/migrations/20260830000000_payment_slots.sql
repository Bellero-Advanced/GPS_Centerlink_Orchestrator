-- ═══════════════════════════════════════════════════════
-- Payment Slot Pool System — Bellerox GPS
-- 99-slot pool for 2-digit decimal tagging (฿210.01 - ฿210.99)
-- Supports unlimited vehicles via slot reuse
-- ═══════════════════════════════════════════════════════

-- ── Slot Pool Table ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS cl_payment_slots (
  slot_number     INTEGER PRIMARY KEY CHECK (slot_number BETWEEN 1 AND 99),
  status          VARCHAR(20) NOT NULL DEFAULT 'available',
  device_id       INTEGER,
  invoice_id      UUID,
  reserved_at     TIMESTAMPTZ,
  paid_at         TIMESTAMPTZ,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT valid_status CHECK (status IN ('available', 'reserved', 'paid'))
);

-- Indexes for performance
CREATE INDEX idx_slots_status ON cl_payment_slots (status);
CREATE INDEX idx_slots_expires ON cl_payment_slots (expires_at) WHERE status = 'reserved';
CREATE INDEX idx_slots_device ON cl_payment_slots (device_id) WHERE device_id IS NOT NULL;

-- ── Pre-populate 99 slots ────────────────────────────────

INSERT INTO cl_payment_slots (slot_number, status)
SELECT
  generate_series(1, 99) AS slot_number,
  'available' AS status
ON CONFLICT (slot_number) DO NOTHING;

-- ── Auto-update timestamp trigger ────────────────────────

CREATE OR REPLACE FUNCTION update_cl_payment_slots_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_payment_slots_updated_at
  BEFORE UPDATE ON cl_payment_slots
  FOR EACH ROW
  EXECUTE FUNCTION update_cl_payment_slots_updated_at();

-- ── Helper function: Get available slot ──────────────────

CREATE OR REPLACE FUNCTION get_available_slot()
RETURNS INTEGER AS $$
DECLARE
  available_slot INTEGER;
BEGIN
  SELECT slot_number INTO available_slot
  FROM cl_payment_slots
  WHERE status = 'available'
  ORDER BY slot_number
  LIMIT 1
  FOR UPDATE SKIP LOCKED;

  RETURN available_slot;
END;
$$ LANGUAGE plpgsql;

-- ── Helper function: Reserve slot ────────────────────────

CREATE OR REPLACE FUNCTION reserve_payment_slot(
  p_device_id INTEGER,
  p_invoice_id UUID
)
RETURNS TABLE(slot_number INTEGER, expires_at TIMESTAMPTZ) AS $$
DECLARE
  v_slot INTEGER;
  v_expires TIMESTAMPTZ;
BEGIN
  -- Get available slot
  v_slot := get_available_slot();

  IF v_slot IS NULL THEN
    -- No slots available
    RETURN QUERY SELECT NULL::INTEGER, NULL::TIMESTAMPTZ;
    RETURN;
  END IF;

  -- Reserve slot (15-minute expiry)
  v_expires := now() + INTERVAL '15 minutes';

  UPDATE cl_payment_slots
  SET
    status = 'reserved',
    device_id = p_device_id,
    invoice_id = p_invoice_id,
    reserved_at = now(),
    expires_at = v_expires,
    paid_at = NULL
  WHERE cl_payment_slots.slot_number = v_slot;

  RETURN QUERY SELECT v_slot, v_expires;
END;
$$ LANGUAGE plpgsql;

-- ── Helper function: Release slot ────────────────────────

CREATE OR REPLACE FUNCTION release_payment_slot(p_slot_number INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE cl_payment_slots
  SET
    status = 'available',
    device_id = NULL,
    invoice_id = NULL,
    reserved_at = NULL,
    paid_at = NULL,
    expires_at = NULL
  WHERE slot_number = p_slot_number;
END;
$$ LANGUAGE plpgsql;

-- ── Helper function: Mark slot as paid ───────────────────

CREATE OR REPLACE FUNCTION mark_slot_paid(p_slot_number INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
  updated_rows INTEGER;
BEGIN
  UPDATE cl_payment_slots
  SET
    status = 'paid',
    paid_at = now()
  WHERE slot_number = p_slot_number
    AND status = 'reserved';

  GET DIAGNOSTICS updated_rows = ROW_COUNT;
  RETURN updated_rows > 0;
END;
$$ LANGUAGE plpgsql;

-- ── Stats function for admin dashboard ───────────────────

CREATE OR REPLACE FUNCTION get_slot_stats()
RETURNS TABLE(
  available_count INTEGER,
  reserved_count INTEGER,
  paid_count INTEGER,
  utilization_percent NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) FILTER (WHERE status = 'available')::INTEGER AS available_count,
    COUNT(*) FILTER (WHERE status = 'reserved')::INTEGER AS reserved_count,
    COUNT(*) FILTER (WHERE status = 'paid')::INTEGER AS paid_count,
    ROUND(
      (COUNT(*) FILTER (WHERE status != 'available')::NUMERIC / 99.0) * 100,
      2
    ) AS utilization_percent
  FROM cl_payment_slots;
END;
$$ LANGUAGE plpgsql;

-- ── Row Level Security ────────────────────────────────────

ALTER TABLE cl_payment_slots ENABLE ROW LEVEL SECURITY;

-- Service role can do everything (Edge Functions)
CREATE POLICY "service_role_all" ON cl_payment_slots
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Authenticated users can only read
CREATE POLICY "authenticated_read" ON cl_payment_slots
  FOR SELECT
  TO authenticated
  USING (true);
