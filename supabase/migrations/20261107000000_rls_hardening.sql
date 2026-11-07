-- ═══════════════════════════════════════════════════════════════════
-- RLS hardening — IDEMPOTENT migration
--
-- Audit finding (plan T026): two tables created by
-- 20260920000000_dlt_manual_override.sql never had RLS enabled:
--
--   • dlt_manual_overrides    — latitude/longitude (PDPA personal data),
--                                created_by operator identity
--   • dlt_transmission_logs   — full GPS request bodies sent to the DLT portal
--
-- With RLS off, Supabase exposes any table in the `public` schema to the
-- `anon` role, i.e. anyone holding the publishable key can SELECT every row.
-- That key ships in the frontend bundle.
--
-- Access model for these tables (matches how the app actually uses them):
--   The frontend authenticates against Traccar, not Supabase, so there is no
--   Supabase session → policies must target `anon`. This is the same constraint
--   recorded for the operational tables and in memory
--   "Supabase RLS ต้องให้ anon". Tightening beyond this requires the tenant id
--   to be written into each row first (plan T017).
--
-- Also applies RLS to the slot-cleanup log, which had none.
-- ═══════════════════════════════════════════════════════════════════

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'dlt_manual_overrides',
    'dlt_transmission_logs',
    'cl_slot_cleanup_log'
  ]
  LOOP
    -- Skip tables that do not exist in this environment rather than failing
    -- the whole migration.
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = tbl
    ) THEN
      RAISE NOTICE 'skipping %, table not present', tbl;
      CONTINUE;
    END IF;

    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);

    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', tbl || '_service_all', tbl);
    EXECUTE format(
      'CREATE POLICY %I ON %I FOR ALL TO service_role USING (true) WITH CHECK (true)',
      tbl || '_service_all', tbl
    );

    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', tbl || '_anon_all', tbl);
    EXECUTE format(
      'CREATE POLICY %I ON %I FOR ALL TO anon USING (true) WITH CHECK (true)',
      tbl || '_anon_all', tbl
    );
  END LOOP;
END $$;

-- ── Verification helper ─────────────────────────────────────────────
-- Run this after applying; every row must show rowsecurity = true.
--
--   SELECT tablename, rowsecurity
--     FROM pg_tables
--    WHERE schemaname = 'public'
--      AND tablename IN (
--        'dlt_manual_overrides', 'dlt_transmission_logs', 'cl_slot_cleanup_log',
--        'cl_fuel_logs', 'cl_maintenance_records', 'cl_predictive_maintenance',
--        'cl_inspections', 'cl_dispatch_orders', 'cl_dispatch_messages',
--        'cl_alert_rules', 'cl_payment_slots', 'cl_payment_queue',
--        'billing_subscriptions', 'billing_invoices', 'billing_payment_events'
--      )
--    ORDER BY rowsecurity, tablename;