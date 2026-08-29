-- Migration 024: Index for Events and Geofences
-- Phase 4: Database Performance Optimization
-- Date: 2026-08-25
-- Target: Optimize alert/event queries and geofence lookups

-- ========================================
-- EVENTS INDEXES
-- ========================================

-- Index 1: Device + event time (alert history)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tc_events_device_time
ON tc_events (deviceid, eventtime DESC);

-- Index 2: Tenant + event time (tenant-scoped alerts)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tc_events_tenant_time
ON tc_events (attributes->>'tenantId', eventtime DESC)
WHERE attributes ? 'tenantId';

-- Index 3: Event type (filter by alert type)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tc_events_type
ON tc_events (type);

-- ========================================
-- GEOFENCES INDEXES
-- ========================================

-- Index 1: Tenant geofences (multi-tenant)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tc_geofences_tenant
ON tc_geofences (attributes->>'tenantId')
WHERE attributes ? 'tenantId';

-- Index 2: Geofence name search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tc_geofences_name
ON tc_geofences USING gin(to_tsvector('english', name));

-- ========================================
-- BENEFITS
-- ========================================
-- ✅ Alert page: Fast event history per device
-- ✅ Tenant alerts: Filtered by tenant
-- ✅ Event type filter: Speeding, geofence, idle
-- ✅ Geofence list: Tenant-scoped
-- ✅ Geofence search: Full-text search on name

-- ========================================
-- INDEX SIZE ESTIMATION
-- ========================================
-- Events: ~1M rows (growing)
-- Geofences: ~1,000 rows
-- Total index size: ~50 MB

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    event_indexes INTEGER;
    geofence_indexes INTEGER;
BEGIN
    -- Count event indexes
    SELECT COUNT(*) INTO event_indexes
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'tc_events'
      AND indexname LIKE 'idx_tc_events%';

    -- Count geofence indexes
    SELECT COUNT(*) INTO geofence_indexes
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'tc_geofences'
      AND indexname LIKE 'idx_tc_geofences%';

    IF event_indexes >= 3 AND geofence_indexes >= 2 THEN
        RAISE NOTICE 'Migration 024: ✅ % event indexes, % geofence indexes created',
            event_indexes, geofence_indexes;
    ELSE
        RAISE EXCEPTION 'Expected 3+ event indexes and 2+ geofence indexes, found % and %',
            event_indexes, geofence_indexes;
    END IF;
END $$;

-- ========================================
-- USAGE EXAMPLES
-- ========================================

-- Get recent alerts for device
-- EXPLAIN ANALYZE
-- SELECT * FROM tc_events
-- WHERE deviceid = 123
-- ORDER BY eventtime DESC
-- LIMIT 50;
-- → Index Scan using idx_tc_events_device_time

-- Get all geofence violations for tenant
-- EXPLAIN ANALYZE
-- SELECT * FROM tc_events
-- WHERE attributes->>'tenantId' = '1'
--   AND type = 'geofenceExit'
-- ORDER BY eventtime DESC;
-- → Index Scan using idx_tc_events_tenant_time + Filter on type

-- Search geofences by name
-- EXPLAIN ANALYZE
-- SELECT * FROM tc_geofences
-- WHERE to_tsvector('english', name) @@ to_tsquery('warehouse');
-- → Bitmap Index Scan using idx_tc_geofences_name
