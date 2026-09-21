-- DLT Manual Override System — IDEMPOTENT migration
-- Tracks vehicles that need manual DLT transmission (because GPS unit_id ≠ DLT unit_id)

-- Create tables if not exist
CREATE TABLE IF NOT EXISTS dlt_manual_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id INTEGER NOT NULL REFERENCES tc_devices(id) ON DELETE CASCADE,
  latitude NUMERIC(10, 7) NOT NULL,
  longitude NUMERIC(10, 7) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('moving', 'idle', 'stopped', 'offline')),
  speed_kmh INTEGER NOT NULL DEFAULT 0,
  course INTEGER NOT NULL DEFAULT 0,
  reason TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  stopped_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS dlt_transmission_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id INTEGER REFERENCES tc_devices(id) ON DELETE SET NULL,
  request_body JSONB NOT NULL,
  response_status INTEGER,
  response_body JSONB,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add new columns if not exist (safe for re-run)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='dlt_manual_overrides' AND column_name='custom_unit_id') THEN
    ALTER TABLE dlt_manual_overrides ADD COLUMN custom_unit_id TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='dlt_manual_overrides' AND column_name='vender_id') THEN
    ALTER TABLE dlt_manual_overrides ADD COLUMN vender_id TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='dlt_manual_overrides' AND column_name='username') THEN
    ALTER TABLE dlt_manual_overrides ADD COLUMN username TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='dlt_manual_overrides' AND column_name='last_transmission_at') THEN
    ALTER TABLE dlt_manual_overrides ADD COLUMN last_transmission_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='dlt_manual_overrides' AND column_name='last_transmission_status') THEN
    ALTER TABLE dlt_manual_overrides ADD COLUMN last_transmission_status TEXT;
  END IF;

  -- dlt_transmission_logs columns
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='dlt_transmission_logs' AND column_name='custom_unit_id') THEN
    ALTER TABLE dlt_transmission_logs ADD COLUMN custom_unit_id TEXT;
  END IF;
END $$;

-- Add constraints (safe re-run with conditional checks)
DO $$
BEGIN
  -- Unique constraint on custom_unit_id
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dlt_manual_overrides_custom_unit_id_key') THEN
    ALTER TABLE dlt_manual_overrides ADD CONSTRAINT dlt_manual_overrides_custom_unit_id_key UNIQUE (custom_unit_id);
  END IF;

  -- NOT NULL for custom_unit_id (skip if NULL data exists)
  IF NOT EXISTS (SELECT 1 FROM dlt_manual_overrides WHERE custom_unit_id IS NULL) THEN
    ALTER TABLE dlt_manual_overrides ALTER COLUMN custom_unit_id SET NOT NULL;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM dlt_manual_overrides WHERE vender_id IS NULL) THEN
    ALTER TABLE dlt_manual_overrides ALTER COLUMN vender_id SET NOT NULL;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM dlt_manual_overrides WHERE username IS NULL) THEN
    ALTER TABLE dlt_manual_overrides ALTER COLUMN username SET NOT NULL;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM dlt_transmission_logs WHERE custom_unit_id IS NULL) THEN
    ALTER TABLE dlt_transmission_logs ALTER COLUMN custom_unit_id SET NOT NULL;
  END IF;
END $$;

-- Indexes (all IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_dlt_manual_device_id ON dlt_manual_overrides(device_id);
CREATE INDEX IF NOT EXISTS idx_dlt_manual_active ON dlt_manual_overrides(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_dlt_transmission_log_sent_at ON dlt_transmission_logs(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_dlt_transmission_log_unit_id ON dlt_transmission_logs(custom_unit_id);
