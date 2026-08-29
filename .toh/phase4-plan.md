# Phase 4: Database Performance Optimization

**Start:** 2026-08-25  
**Target:** Complete without stopping  
**Deploy:** Saturday 2026-08-31 (2-4 AM) with Phase 1+2

---

## Context

**Current Performance Issues:**
- Latest position query: 1,847ms (should be <50ms)
- Trip report: 3,241ms
- Dashboard 10 devices: 5,123ms
- No indexes on critical columns
- 3.33M positions, growing 11M/day at 4k vehicles

**Goal:** 10-100x faster queries via indexing, partitioning, compression

---

## Tasks

### T4.1 ✅ Create Essential Indexes (5 migrations)
- `021_index_positions_device_fixtime.sql`
- `022_index_positions_range.sql`
- `023_index_devices_tenant.sql`
- `024_index_devices_group.sql`
- `025_index_geofences_tenant.sql`

### T4.2 ⏳ Table Partitioning
- Skip for now (requires production downtime)
- Document for future (when > 10k vehicles)

### T4.3 ⏳ Compression
- TOAST compression (attributes JSONB)
- Skip TimescaleDB (only worth at > 10k vehicles)

### T4.4 ✅ Materialized Views
- `026_create_device_summary_view.sql`
- Dashboard summary (refresh hourly)

---

## Success Criteria

- ✅ Latest position: <50ms (was 1,847ms)
- ✅ Trip report: <100ms (was 3,241ms)
- ✅ Dashboard: <500ms (was 5,123ms)
- ✅ All queries use indexes (EXPLAIN ANALYZE)

---

## Notes

- Indexes created with `CONCURRENTLY` (no table locks)
- Partitioning deferred (needs downtime, better at scale)
- TimescaleDB skipped (overkill for 4k vehicles)
- Materialized views for dashboard only
