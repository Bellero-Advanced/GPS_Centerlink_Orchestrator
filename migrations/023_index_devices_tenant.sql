-- Migration 023: Index for Multi-Tenant Device Queries
-- Phase 4: Database Performance Optimization
-- Date: 2026-08-25
-- Target: Optimize tenant-scoped device lists

-- ========================================
-- PROBLEM
-- ========================================
-- Query: Get all devices for tenant
-- SELECT * FROM tc_devices WHERE tenant_id = 1;
--
-- Query: Get devices by group (for supervisor role)
-- SELECT * FROM tc_devices WHERE groupid = 5;
--
-- Current: Full table scan on 4,000+ devices

-- ========================================
-- SOLUTION: Tenant + Group Indexes
-- ========================================

-- Index 1: tenant_id (multi-tenant queries)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tc_devices_tenant
ON tc_devices (tenant_id)
WHERE tenant_id IS NOT NULL;

-- Index 2: groupid (supervisor role, group-scoped access)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tc_devices_group
ON tc_devices (groupid)
WHERE groupid IS NOT NULL;

-- Index 3: Composite for tenant + group filtering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tc_devices_tenant_group
ON tc_devices (tenant_id, groupid)
WHERE tenant_id IS NOT NULL AND groupid IS NOT NULL;

-- ========================================
-- BENEFITS
-- ========================================
-- ✅ Fleet page load: Faster device list by tenant
-- ✅ Supervisor role: Fast group-scoped queries
-- ✅ Device assignment: Faster tenant lookups
-- ✅ Partial indexes: Only rows with tenant_id/groupid set

-- ========================================
-- INDEX SIZE ESTIMATION
-- ========================================
-- Devices: 4,000 → 20,000 (future)
-- Index size per index: ~1-2 MB (tiny)
-- Total: ~6 MB (all 3 indexes)

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    index_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'tc_devices'
      AND indexname IN (
          'idx_tc_devices_tenant',
          'idx_tc_devices_group',
          'idx_tc_devices_tenant_group'
      );

    IF index_count = 3 THEN
        RAISE NOTICE 'Migration 023: ✅ 3 device indexes created';
    ELSE
        RAISE EXCEPTION 'Expected 3 indexes, found %', index_count;
    END IF;
END $$;

-- ========================================
-- USAGE EXAMPLES
-- ========================================

-- Tenant admin: Get all devices
-- EXPLAIN ANALYZE SELECT * FROM tc_devices WHERE tenant_id = 1;
-- → Index Scan using idx_tc_devices_tenant

-- Supervisor: Get devices in assigned groups
-- EXPLAIN ANALYZE SELECT * FROM tc_devices WHERE groupid IN (5, 7, 12);
-- → Bitmap Index Scan using idx_tc_devices_group

-- Combined: Tenant + group filter
-- EXPLAIN ANALYZE SELECT * FROM tc_devices WHERE tenant_id = 1 AND groupid = 5;
-- → Index Scan using idx_tc_devices_tenant_group
