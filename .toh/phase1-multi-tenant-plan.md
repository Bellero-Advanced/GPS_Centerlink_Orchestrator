# Phase 1: Multi-Tenant Database Implementation Plan

**Status:** Ready for approval  
**Duration:** 2 weeks  
**Cost:** ฿0 infrastructure (same VM, add columns only)

---

## Executive Summary

Enable 10 tenants to share one PostgreSQL database with:
- Complete data isolation via Row-Level Security (RLS)
- Zero infrastructure cost (add columns to existing tables)
- Backward compatible (existing GPS Thailand = tenant_id 1)
- Sub-5ms query overhead

---

## Current State Analysis

### Existing Tables (Traccar core)
- `tc_users` — user accounts (214 vehicles = ~20 users)
- `tc_devices` — vehicles (214 devices)
- `tc_positions` — GPS positions (3.33M rows)
- `tc_groups` — device groups
- `tc_geofences` — polygons
- `tc_drivers`, `tc_notifications`, etc.

### Custom Tables (our migrations)
- `drivers` — employee info (migration 001)
- `trailers` — trailer tracking (002)
- `speed_groups` — speed limits (003)
- `rfid_cards` — RFID tags (004)
- `maintenance_records` — maintenance (005)
- `email_report_configs` — email alerts (006)
- `alert_configs` — alert rules (007)

### Migration System
- **Location:** `/bellerox-gps-web/migrations/`
- **Runner:** `run-migrations.sh` (uses psql)
- **Separate from Traccar:** Traccar uses Liquibase, we use plain SQL

---

## Implementation Strategy

### Approach: Shared Tables + Row-Level Security

**Why NOT separate databases?**
- ❌ Cost: $200/month per Cloud SQL × 10 = $2,000/month
- ❌ Operations: 10 databases to backup, monitor, patch
- ✅ Single database: Same $97/month VM, add tenants instantly

**Why Row-Level Security (RLS)?**
- ✅ Database-enforced isolation (even app bugs can't leak data)
- ✅ Automatic filtering (WHERE tenant_id = X added by PostgreSQL)
- ✅ Minimal app changes (just set session variable)

---

## Database Schema Design

### New Tables

```sql
-- Tenants (companies)
CREATE TABLE tenants (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(50) UNIQUE NOT NULL,  -- URL-safe: gps-thailand
    name VARCHAR(255) NOT NULL,        -- Display: GPS Thailand Company
    domain VARCHAR(255),               -- Optional custom domain
    config JSONB DEFAULT '{}',         -- Branding, features, limits
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,            -- Soft delete
    
    CONSTRAINT slug_format CHECK (slug ~ '^[a-z0-9-]+$')
);

-- Seed first tenant (GPS Thailand)
INSERT INTO tenants (id, slug, name) VALUES 
    (1, 'gps-thailand', 'GPS Thailand Company');
```

### Modified Tables (add tenant_id column)

**Traccar Core Tables:**
- `tc_users` → add `tenant_id INT REFERENCES tenants(id)`
- `tc_devices` → add `tenant_id INT`
- `tc_groups` → add `tenant_id INT`
- `tc_geofences` → add `tenant_id INT`
- `tc_drivers` → add `tenant_id INT`
- `tc_notifications` → add `tenant_id INT`

**Our Custom Tables:**
- `drivers` → add `tenant_id INT`
- `trailers` → add `tenant_id INT`
- `speed_groups` → add `tenant_id INT`
- etc.

**NOT modified:**
- `tc_positions` — too large (3.33M rows), use JOIN to tc_devices instead

### Row-Level Security Policies

```sql
-- Enable RLS on tc_users
ALTER TABLE tc_users ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see users in their tenant
CREATE POLICY tenant_isolation_users ON tc_users
    USING (tenant_id = current_setting('app.current_tenant')::integer);

-- Repeat for all tenant-scoped tables
```

---

## Migration Plan (Zero Downtime)

### Phase 1A: Create New Tables (Non-Blocking)
**File:** `migrations/009_create_tenants.sql`
**Time:** 1 second, no locks

```sql
CREATE TABLE tenants (...);
INSERT INTO tenants (id, slug, name) VALUES (1, 'gps-thailand', 'GPS Thailand Company');
```

### Phase 1B: Add Nullable Columns (Non-Blocking)
**File:** `migrations/010_add_tenant_id_columns.sql`
**Time:** ~2 seconds per table (214 devices = fast)

```sql
-- Add nullable tenant_id (backward compatible)
ALTER TABLE tc_users ADD COLUMN tenant_id INTEGER REFERENCES tenants(id);
ALTER TABLE tc_devices ADD COLUMN tenant_id INTEGER;
ALTER TABLE tc_groups ADD COLUMN tenant_id INTEGER;
-- ... repeat for all tables
```

**Why nullable first?**
- Allows adding column without rewriting table
- Existing data still works (NULL = legacy)

### Phase 1C: Backfill Data (Background, Batched)
**File:** `migrations/011_backfill_tenant_id.sql`
**Time:** ~10 seconds (214 devices + 20 users)

```sql
-- Backfill existing data as tenant 1 (GPS Thailand)
UPDATE tc_users SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE tc_devices SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE tc_groups SET tenant_id = 1 WHERE tenant_id IS NULL;
-- ... repeat
```

### Phase 1D: Make NOT NULL (Brief Lock)
**File:** `migrations/012_make_tenant_id_required.sql`
**Time:** ~1 second per table
**Downtime:** Schedule at 3 AM, announce maintenance

```sql
-- After backfill, make required
ALTER TABLE tc_users ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE tc_devices ALTER COLUMN tenant_id SET NOT NULL;
-- ... repeat
```

### Phase 1E: Enable RLS (Non-Blocking)
**File:** `migrations/013_enable_row_level_security.sql`
**Time:** < 1 second
**Performance:** Adds ~0.5-2ms per query

```sql
-- Enable RLS
ALTER TABLE tc_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_users ON tc_users
    USING (tenant_id = current_setting('app.current_tenant')::integer);
    
-- Repeat for all tables
```

### Phase 1F: Add Indexes (Background)
**File:** `migrations/014_add_tenant_indexes.sql`
**Time:** ~5 seconds (CONCURRENTLY = no locks)

```sql
CREATE INDEX CONCURRENTLY idx_users_tenant ON tc_users(tenant_id);
CREATE INDEX CONCURRENTLY idx_devices_tenant ON tc_devices(tenant_id);
-- ... repeat
```

---

## Backend Changes

### Middleware: Tenant Context Injection

**New file:** `src/server/middleware/tenantContext.ts`

```typescript
export async function tenantContextMiddleware(req: Request, res: Response, next: NextFunction) {
    let tenantId: number | null = null;
    
    // Method 1: JWT claim (from auth middleware)
    if (req.user?.tenantId) {
        tenantId = req.user.tenantId;
    }
    
    // Method 2: Subdomain (tenant-slug.gps.bellerox.com)
    else if (req.hostname !== 'gps.bellerox.com') {
        const subdomain = req.hostname.split('.')[0];
        const result = await pool.query(
            'SELECT id FROM tenants WHERE slug = $1',
            [subdomain]
        );
        tenantId = result.rows[0]?.id;
    }
    
    if (!tenantId) {
        return res.status(400).json({ error: 'Tenant not found' });
    }
    
    // Set PostgreSQL session variable (RLS uses this)
    await pool.query('SET LOCAL app.current_tenant = $1', [tenantId]);
    
    req.tenantId = tenantId;
    next();
}
```

**Apply globally:**
```typescript
// src/server/index.ts
app.use('/api', authMiddleware);        // First: authenticate
app.use('/api', tenantContextMiddleware); // Second: set tenant
app.use('/api', routes);                // Third: handle routes
```

**Result:** All queries automatically filtered by RLS!

### Tenant Management API

**New file:** `src/server/routes/admin/tenants.ts`

```typescript
// POST /api/admin/tenants — Create tenant (super-admin only)
router.post('/tenants', requireSuperAdmin, async (req, res) => {
    const { slug, name } = req.body;
    
    const result = await pool.query(`
        INSERT INTO tenants (slug, name)
        VALUES ($1, $2)
        RETURNING *
    `, [slug, name]);
    
    res.status(201).json(result.rows[0]);
});

// GET /api/admin/tenants — List all tenants
router.get('/tenants', requireSuperAdmin, async (req, res) => {
    const result = await pool.query(`
        SELECT 
            t.id, t.slug, t.name, t.created_at,
            COUNT(DISTINCT d.id) AS device_count,
            COUNT(DISTINCT u.id) AS user_count
        FROM tenants t
        LEFT JOIN tc_devices d ON t.id = d.tenant_id
        LEFT JOIN tc_users u ON t.id = u.tenant_id
        WHERE t.deleted_at IS NULL
        GROUP BY t.id
        ORDER BY t.created_at DESC
    `);
    
    res.json(result.rows);
});
```

---

## Frontend Changes

### Tenant Context Provider

**New file:** `src/contexts/TenantContext.tsx`

```typescript
interface TenantContextValue {
    tenantId: number | null;
    tenantSlug: string | null;
    config: Record<string, any>;
    loading: boolean;
}

export function TenantProvider({ children }: { children: React.ReactNode }) {
    const [tenant, setTenant] = useState<TenantContextValue>({
        tenantId: null,
        tenantSlug: null,
        config: {},
        loading: true,
    });
    
    useEffect(() => {
        async function loadTenant() {
            // Detect subdomain or fetch from API
            const response = await fetch('/api/tenant/config');
            const data = await response.json();
            
            setTenant({
                tenantId: data.id,
                tenantSlug: data.slug,
                config: data.config || {},
                loading: false,
            });
            
            // Apply branding (if configured)
            if (data.config?.primaryColor) {
                document.documentElement.style.setProperty(
                    '--color-primary',
                    data.config.primaryColor
                );
            }
        }
        
        loadTenant();
    }, []);
    
    return (
        <TenantContext.Provider value={tenant}>
            {children}
        </TenantContext.Provider>
    );
}
```

### Admin UI: Tenant Management

**New file:** `src/pages/admin/TenantsPage.tsx`

- List tenants (table view)
- Create tenant (modal form)
- View tenant details (device/user count)
- Soft delete tenant

---

## Testing Strategy

### Unit Tests

**New file:** `src/server/__tests__/tenantIsolation.test.ts`

```typescript
describe('Multi-Tenant Security', () => {
    it('should only return devices for current tenant', async () => {
        await pool.query('SET LOCAL app.current_tenant = 1');
        
        const result = await pool.query('SELECT * FROM tc_devices');
        
        // Should only see tenant 1's devices
        expect(result.rows.every(d => d.tenant_id === 1)).toBe(true);
    });
    
    it('should block explicit cross-tenant query', async () => {
        await pool.query('SET LOCAL app.current_tenant = 1');
        
        // Try to access tenant 2's device
        const result = await pool.query(
            'SELECT * FROM tc_devices WHERE tenant_id = 2'
        );
        
        // RLS should block it
        expect(result.rows).toHaveLength(0);
    });
});
```

### Integration Tests

1. **Create 2 test tenants**
2. **Add devices to each**
3. **Query as tenant 1** → should only see tenant 1 devices
4. **Query as tenant 2** → should only see tenant 2 devices
5. **Try SQL injection** → should be blocked by RLS

### Performance Tests

- Measure query latency before/after RLS
- Target: < 5ms overhead
- Run with 10 tenants × 400 devices = 4,000 total

---

## Rollback Plan

### If RLS causes issues:

**Step 1: Disable RLS (immediate)**
```sql
ALTER TABLE tc_devices DISABLE ROW LEVEL SECURITY;
ALTER TABLE tc_users DISABLE ROW LEVEL SECURITY;
```

**Step 2: Add app-layer filter (temporary)**
```typescript
// Add to all queries until RLS is fixed
const devices = await pool.query(
    'SELECT * FROM tc_devices WHERE tenant_id = $1',
    [req.tenantId]
);
```

**Step 3: Debug and re-enable**

---

## Task Breakdown (18 tasks, 2 weeks)

### Week 1: Database & Backend

**Day 1-2: Database Migrations**
- [ ] T1.1: Create `tenants` table (009_create_tenants.sql)
- [ ] T1.2: Add nullable `tenant_id` columns (010_add_tenant_id_columns.sql)
- [ ] T1.3: Backfill existing data (011_backfill_tenant_id.sql)
- [ ] T1.4: Test on local copy of production DB
- [ ] T1.5: Deploy to staging

**Day 3: Make Required & RLS**
- [ ] T1.6: Make `tenant_id` NOT NULL (012_make_tenant_id_required.sql)
- [ ] T1.7: Enable RLS policies (013_enable_row_level_security.sql)
- [ ] T1.8: Add indexes (014_add_tenant_indexes.sql)
- [ ] T1.9: Verify query plans (EXPLAIN ANALYZE)

**Day 4-5: Backend API**
- [ ] T1.10: Create `tenantContext` middleware
- [ ] T1.11: Create tenant CRUD endpoints
- [ ] T1.12: Update auth to include `tenantId` in JWT
- [ ] T1.13: Test with Postman (create tenant, query devices)

### Week 2: Frontend & Testing

**Day 6-7: Frontend**
- [ ] T1.14: Create `TenantContext` provider
- [ ] T1.15: Create `TenantsPage` (admin UI)
- [ ] T1.16: Update layout to load tenant config
- [ ] T1.17: Test subdomain detection

**Day 8-9: Testing**
- [ ] T1.18: Write security tests (cross-tenant isolation)
- [ ] T1.19: Write integration tests
- [ ] T1.20: Performance test (10 tenants × 400 devices)

**Day 10: Deploy**
- [ ] T1.21: Deploy migrations to production (3 AM maintenance)
- [ ] T1.22: Monitor query performance for 24 hours
- [ ] T1.23: Update documentation

---

## Success Criteria

- ✅ 10 tenants running in production
- ✅ No cross-tenant data leaks (security audit passes)
- ✅ Query performance < 5% degradation
- ✅ All tests pass (unit + integration)
- ✅ Rollback procedure tested

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| RLS overhead > 5ms | Medium | Disable RLS, use app-layer filter temporarily |
| Migration breaks Traccar | High | Test on staging first, have rollback SQL ready |
| Cross-tenant data leak | Critical | Extensive testing, pen test before production |
| Query N+1 issues | Medium | Eager loading, monitor query count |

---

## Decision Log

**Why RLS over app-layer filtering?**
- Database-enforced = safer (even app bugs can't leak)
- Automatic filtering = less code to maintain
- Performance acceptable (0.5-2ms overhead)

**Why NOT separate schemas per tenant?**
- More complex (need to switch schemas dynamically)
- Harder to query across tenants (analytics, admin)
- RLS is simpler and battle-tested

**Why backfill in separate migration?**
- Non-blocking (can run in background)
- Easier to rollback if fails
- Clear separation of concerns

---

**Status:** Ready for approval  
**Next:** Approve plan → Execute T1.1-T1.23
