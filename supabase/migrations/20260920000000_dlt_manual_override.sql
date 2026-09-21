-- Migration: DLT Manual Override Tables
-- Created: 2026-09-20
-- Purpose: Support manual GPS position submission when device is broken

-- ============================================================================
-- Table 1: dlt_manual_overrides
-- Stores active manual override configurations (lat/lng + status per device)
-- ============================================================================

CREATE TABLE IF NOT EXISTS dlt_manual_overrides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id int NOT NULL,
  latitude numeric(10,7) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude numeric(10,7) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  status text NOT NULL CHECK (status IN ('moving', 'idle', 'stopped')),
  speed_kmh int NOT NULL DEFAULT 0 CHECK (speed_kmh BETWEEN 0 AND 200),
  course int NOT NULL DEFAULT 0 CHECK (course BETWEEN 0 AND 359),
  reason text NOT NULL,
  created_by text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  stopped_at timestamptz,
  is_active boolean GENERATED ALWAYS AS (stopped_at IS NULL) STORED
);

-- Foreign key to tc_devices (no cascade - device deletion is rare, manual check safer)
ALTER TABLE dlt_manual_overrides
  ADD CONSTRAINT fk_device
  FOREIGN KEY (device_id) REFERENCES tc_devices(id);

COMMENT ON TABLE dlt_manual_overrides IS 'Manual GPS position overrides for DLT submission when device is broken';
COMMENT ON COLUMN dlt_manual_overrides.is_active IS 'Generated: true when stopped_at IS NULL';
COMMENT ON COLUMN dlt_manual_overrides.reason IS 'Why override was created (e.g., "GPS box broken, waiting for service team")';

-- Indexes for common queries
CREATE INDEX idx_dlt_manual_overrides_device_active ON dlt_manual_overrides(device_id, is_active);
CREATE INDEX idx_dlt_manual_overrides_created_at ON dlt_manual_overrides(created_at DESC);

-- ============================================================================
-- Table 2: dlt_transmission_log
-- Records every DLT batch transmission (sent every 60s by Edge Function)
-- ============================================================================

CREATE TABLE IF NOT EXISTS dlt_transmission_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sent_at timestamptz NOT NULL DEFAULT now(),
  batch jsonb NOT NULL,
  response jsonb,
  http_status int,
  success boolean NOT NULL,
  error_message text,
  manual_device_ids int[]
);

COMMENT ON TABLE dlt_transmission_log IS 'Log of all DLT batch transmissions (auto + manual positions)';
COMMENT ON COLUMN dlt_transmission_log.batch IS 'Full DLT payload sent (vender_id + locations[])';
COMMENT ON COLUMN dlt_transmission_log.response IS 'DLT API response body';
COMMENT ON COLUMN dlt_transmission_log.manual_device_ids IS 'Device IDs that were manual overrides in this batch';

-- Indexes for history queries
CREATE INDEX idx_dlt_transmission_log_sent_at ON dlt_transmission_log(sent_at DESC);
CREATE INDEX idx_dlt_transmission_log_success_sent_at ON dlt_transmission_log(success, sent_at DESC);

-- ============================================================================
-- RLS Policies
-- Following existing pattern from 001_cl_tenants.sql
-- ============================================================================

-- Enable RLS
ALTER TABLE dlt_manual_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE dlt_transmission_log ENABLE ROW LEVEL SECURITY;

-- Policy 1: authenticated users can read
CREATE POLICY authenticated_read_overrides ON dlt_manual_overrides
  FOR SELECT TO authenticated USING (true);

CREATE POLICY authenticated_read_log ON dlt_transmission_log
  FOR SELECT TO authenticated USING (true);

-- Policy 2: service_role can do everything (Edge Function writes)
CREATE POLICY service_role_all_overrides ON dlt_manual_overrides
  FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY service_role_all_log ON dlt_transmission_log
  FOR ALL TO service_role USING (true) WITH CHECK (true);
