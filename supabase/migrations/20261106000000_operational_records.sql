-- ═══════════════════════════════════════════════════════════════════
-- Operational records — IDEMPOTENT migration
--
-- Why: six pages (Fuel, Maintenance, Inspection, Dispatch, Predictive
-- Maintenance, Alert Rules) persisted business records in localStorage.
-- Records therefore vanished on a different device or a cleared profile.
-- These tables move them into Postgres so a whole team sees the same data.
--
-- Access model (matches the existing app):
--   • The app authenticates against TRAccar, not Supabase, so there is no
--     Supabase session. RLS must therefore grant `anon` — the same lesson
--     recorded in memory "Supabase RLS ต้องให้ anon".
--   • `service_role` keeps full access for backfills and Edge Functions.
-- ═══════════════════════════════════════════════════════════════════

-- ── Fuel logs ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cl_fuel_logs (
  id           TEXT PRIMARY KEY,
  date         DATE        NOT NULL,
  vehicle_name TEXT        NOT NULL,
  liters       NUMERIC(10,2) NOT NULL CHECK (liters > 0),
  price_baht   NUMERIC(12,2) NOT NULL CHECK (price_baht >= 0),
  station      TEXT,
  recorded_by  TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_cl_fuel_logs_date ON cl_fuel_logs (date DESC);

-- ── Maintenance schedules ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cl_maintenance_records (
  id               TEXT PRIMARY KEY,
  device_idx       INTEGER NOT NULL,
  device_fallback  TEXT,
  type             TEXT    NOT NULL,
  due_date         DATE,
  due_mileage      INTEGER DEFAULT 0,
  last_mileage     INTEGER DEFAULT 0,
  status           TEXT    NOT NULL DEFAULT 'upcoming'
                   CHECK (status IN ('upcoming','due_soon','overdue','completed')),
  note             TEXT,
  recurrence       TEXT DEFAULT 'none',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_cl_mx_due_date ON cl_maintenance_records (due_date);

-- ── Predictive maintenance ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cl_predictive_maintenance (
  id             TEXT PRIMARY KEY,
  device_id      INTEGER NOT NULL,
  device_name    TEXT,
  type           TEXT NOT NULL DEFAULT 'other',
  label          TEXT,
  date           DATE NOT NULL,
  mileage_km     INTEGER DEFAULT 0,
  next_mileage_km INTEGER DEFAULT 0,
  notes          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_cl_predictive_device ON cl_predictive_maintenance (device_id, date DESC);

-- ── Inspections ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cl_inspections (
  id           TEXT PRIMARY KEY,
  device_id    INTEGER NOT NULL,
  device_name  TEXT,
  driver_name  TEXT,
  date         DATE NOT NULL,
  results      JSONB NOT NULL DEFAULT '[]'::jsonb,
  overall_pass BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_cl_inspections_device ON cl_inspections (device_id, date DESC);

-- ── Dispatch ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cl_dispatch_orders (
  id          TEXT PRIMARY KEY,
  order_no    TEXT NOT NULL,
  customer    TEXT,
  origin      TEXT,
  destination TEXT,
  status      TEXT NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending','assigned','in_transit','delivered','cancelled')),
  device_id   INTEGER,
  driver_name TEXT,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_cl_dispatch_orders_status ON cl_dispatch_orders (status, created_at DESC);

CREATE TABLE IF NOT EXISTS cl_dispatch_messages (
  id         TEXT PRIMARY KEY,
  device_id  INTEGER NOT NULL,
  "from"     TEXT NOT NULL CHECK ("from" IN ('dispatcher','driver')),
  text       TEXT NOT NULL,
  ts         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_cl_dispatch_messages_device ON cl_dispatch_messages (device_id, ts DESC);

-- ── Alert rules ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cl_alert_rules (
  id          TEXT PRIMARY KEY,
  key         TEXT NOT NULL UNIQUE,
  label       TEXT NOT NULL,
  description TEXT,
  enabled     BOOLEAN NOT NULL DEFAULT TRUE,
  threshold   JSONB,
  notify_line BOOLEAN NOT NULL DEFAULT FALSE,
  notify_bell BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ
);

-- ── Row Level Security ──────────────────────────────────────────────
-- The frontend has no Supabase session (Traccar owns auth), so `anon` must be
-- able to read and write these operational tables. Scope tightening must wait
-- until tenant scoping is written into the rows (plan T017).

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'cl_fuel_logs',
    'cl_maintenance_records',
    'cl_predictive_maintenance',
    'cl_inspections',
    'cl_dispatch_orders',
    'cl_dispatch_messages',
    'cl_alert_rules'
  ]
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);

    -- Service role: full access (backfills, Edge Functions)
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', tbl || '_service_all', tbl);
    EXECUTE format(
      'CREATE POLICY %I ON %I FOR ALL TO service_role USING (true) WITH CHECK (true)',
      tbl || '_service_all', tbl
    );

    -- App client: full access (no Supabase session — see note above)
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', tbl || '_anon_all', tbl);
    EXECUTE format(
      'CREATE POLICY %I ON %I FOR ALL TO anon USING (true) WITH CHECK (true)',
      tbl || '_anon_all', tbl
    );
  END LOOP;
END $$;