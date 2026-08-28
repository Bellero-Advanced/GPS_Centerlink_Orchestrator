# Phase 1: Multi-Tenant (Hybrid Architecture)
# Traccar DB + Supabase Integration

**Status:** Ready for execution  
**Duration:** 1.5 weeks (10 days)  
**Cost:** ฿0 infrastructure

---

## Architecture Decision: Hybrid Model

### Why Hybrid?

**Existing State:**
- ✅ Supabase already configured and has 1 tenant
- ✅ Traccar DB has all GPS data (tc_devices, tc_positions)
- ✅ Both databases are production-ready

**Hybrid Approach:**
```
┌─────────────────────────────────────────┐
│   Traccar PostgreSQL (VM)              │
│   ─────────────────────────            │
│                                         │
│  • tc_users           ──┐               │
│  • tc_devices (214)     │               │
│  • tc_positions (3.33M) │ tenant_id     │
│  • tc_groups            │               │
│  • drivers              │               │
│  • tenants (NEW) ←──────┘               │
│                                         │
│  Tenant ID: INTEGER                     │
│  RLS: app.current_tenant                │
└─────────────────────────────────────────┘
                    │
                    │ Sync tenant_id
                    ▼
┌─────────────────────────────────────────┐
│   Supabase PostgreSQL (Cloud)          │
│   ───────────────────────              │
│                                         │
│  • cl_tenants (EXISTING)                │
│    - ID: UUID                           │
│    - slug, domain, status               │
│    - data JSONB (branding, config)      │
│                                         │
│  • billing_subscriptions                │
│  • billing_invoices                     │
│  • billing_payment_events               │
└─────────────────────────────────────────┘
```

**Division of Responsibility:**
- **Traccar DB:** GPS core data + tenant_id (RLS enforcement)
- **Supabase:** Tenant config, branding, billing, payment

**ID Mapping:**
- Traccar `tenants.id` = **INTEGER** (1, 2, 3, ...)
- Supabase `cl_tenants.id` = **UUID**
- Link: `cl_tenants.data->>'traccar_tenant_id'` = `tenants.id`

---

## Implementation Plan

### Part 1: Traccar DB Multi-Tenant (5 days)

**Goal:** Add tenant_id to all tables, enable RLS

#### T1.1: Create tenants table (Day 1, 2 hours)

**File:** `migrations/009_create_tenants.sql`

```sql
-- Tenants table (minimal — main config in Supabase)
CREATE TABLE tenants (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT slug_format CHECK (slug ~ '^[a-z0-9-]+$')
);

-- Seed first tenant (GPS Thailand)
INSERT INTO tenants (id, slug, name) VALUES 
    (1, 'gpsthailand', 'GPS Thailand Company');

-- Indexes
CREATE INDEX idx_tenants_slug ON tenants(slug);

COMMENT ON TABLE tenants IS 'Tenant registry — links to Supabase cl_tenants';
```

**Run:**
```bash
POSTGRES_PASSWORD=xxx bash run-migrations.sh
```

---

#### T1.2: Add tenant_id columns (Day 1, 3 hours)

**File:** `migrations/010_add_tenant_id_columns.sql`

```sql
-- Add nullable tenant_id to core tables
ALTER TABLE tc_users ADD COLUMN tenant_id INTEGER REFERENCES tenants(id);
ALTER TABLE tc_devices ADD COLUMN tenant_id INTEGER;
ALTER TABLE tc_groups ADD COLUMN tenant_id INTEGER;
ALTER TABLE tc_geofences ADD COLUMN tenant_id INTEGER;
ALTER TABLE tc_drivers ADD COLUMN tenant_id INTEGER;
ALTER TABLE tc_notifications ADD COLUMN tenant_id INTEGER;

-- Add to custom tables
ALTER TABLE drivers ADD COLUMN tenant_id INTEGER REFERENCES tenants(id);
ALTER TABLE trailers ADD COLUMN tenant_id INTEGER REFERENCES tenants(id);
ALTER TABLE speed_groups ADD COLUMN tenant_id INTEGER REFERENCES tenants(id);
ALTER TABLE rfid_cards ADD COLUMN tenant_id INTEGER REFERENCES tenants(id);
ALTER TABLE maintenance_records ADD COLUMN tenant_id INTEGER REFERENCES tenants(id);
ALTER TABLE email_report_configs ADD COLUMN tenant_id INTEGER REFERENCES tenants(id);
ALTER TABLE alert_configs ADD COLUMN tenant_id INTEGER REFERENCES tenants(id);

COMMENT ON COLUMN tc_users.tenant_id IS 'Tenant ownership — enforced by RLS';
COMMENT ON COLUMN tc_devices.tenant_id IS 'Tenant ownership — enforced by RLS';
```

---

#### T1.3: Backfill tenant_id (Day 2, 1 hour)

**File:** `migrations/011_backfill_tenant_id.sql`

```sql
-- Backfill all existing data as tenant 1 (GPS Thailand)
UPDATE tc_users SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE tc_devices SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE tc_groups SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE tc_geofences SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE tc_drivers SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE tc_notifications SET tenant_id = 1 WHERE tenant_id IS NULL;

-- Custom tables
UPDATE drivers SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE trailers SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE speed_groups SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE rfid_cards SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE maintenance_records SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE email_report_configs SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE alert_configs SET tenant_id = 1 WHERE tenant_id IS NULL;

-- Verify backfill
SELECT 
    'tc_users' AS table_name,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE tenant_id = 1) AS backfilled
FROM tc_users
UNION ALL
SELECT 'tc_devices', COUNT(*), COUNT(*) FILTER (WHERE tenant_id = 1) FROM tc_devices;
```

---

#### T1.4: Make tenant_id required (Day 2, 1 hour)

**File:** `migrations/012_make_tenant_id_required.sql`

**⚠️ Schedule at 3 AM (brief table locks)**

```sql
-- Make NOT NULL (locks table briefly)
ALTER TABLE tc_users ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE tc_devices ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE tc_groups ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE tc_geofences ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE tc_drivers ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE tc_notifications ALTER COLUMN tenant_id SET NOT NULL;

-- Custom tables
ALTER TABLE drivers ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE trailers ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE speed_groups ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE rfid_cards ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE maintenance_records ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE email_report_configs ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE alert_configs ALTER COLUMN tenant_id SET NOT NULL;
```

---

#### T1.5: Enable Row-Level Security (Day 3, 4 hours)

**File:** `migrations/013_enable_row_level_security.sql`

```sql
-- Enable RLS on core tables
ALTER TABLE tc_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tc_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE tc_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE tc_geofences ENABLE ROW LEVEL SECURITY;
ALTER TABLE tc_drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE tc_notifications ENABLE ROW LEVEL SECURITY;

-- Policies for tc_users
CREATE POLICY tenant_isolation_users ON tc_users
    USING (tenant_id = current_setting('app.current_tenant')::integer);

-- Policies for tc_devices
CREATE POLICY tenant_isolation_devices ON tc_devices
    USING (tenant_id = current_setting('app.current_tenant')::integer);

-- Policies for tc_groups
CREATE POLICY tenant_isolation_groups ON tc_groups
    USING (tenant_id = current_setting('app.current_tenant')::integer);

-- Policies for tc_geofences
CREATE POLICY tenant_isolation_geofences ON tc_geofences
    USING (tenant_id = current_setting('app.current_tenant')::integer);

-- Custom tables
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_drivers ON drivers
    USING (tenant_id = current_setting('app.current_tenant')::integer);

ALTER TABLE trailers ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_trailers ON trailers
    USING (tenant_id = current_setting('app.current_tenant')::integer);

-- Repeat for all custom tables...

-- Special: tc_positions (join to tc_devices)
ALTER TABLE tc_positions ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_positions ON tc_positions
    USING (
        deviceid IN (
            SELECT id FROM tc_devices
            WHERE tenant_id = current_setting('app.current_tenant')::integer
        )
    );

COMMENT ON POLICY tenant_isolation_users ON tc_users IS 
    'Row-Level Security: users can only see users in their tenant';
```

---

#### T1.6: Add indexes (Day 3, 1 hour)

**File:** `migrations/014_add_tenant_indexes.sql`

```sql
-- Create indexes CONCURRENTLY (no table locks)
CREATE INDEX CONCURRENTLY idx_users_tenant ON tc_users(tenant_id);
CREATE INDEX CONCURRENTLY idx_devices_tenant ON tc_devices(tenant_id);
CREATE INDEX CONCURRENTLY idx_groups_tenant ON tc_groups(tenant_id);
CREATE INDEX CONCURRENTLY idx_geofences_tenant ON tc_geofences(tenant_id);
CREATE INDEX CONCURRENTLY idx_drivers_tenant_traccar ON tc_drivers(tenant_id);
CREATE INDEX CONCURRENTLY idx_notifications_tenant ON tc_notifications(tenant_id);

-- Custom tables
CREATE INDEX CONCURRENTLY idx_drivers_tenant ON drivers(tenant_id);
CREATE INDEX CONCURRENTLY idx_trailers_tenant ON trailers(tenant_id);
CREATE INDEX CONCURRENTLY idx_speed_groups_tenant ON speed_groups(tenant_id);

-- Verify indexes created
SELECT schemaname, tablename, indexname 
FROM pg_indexes 
WHERE indexname LIKE '%tenant%'
ORDER BY tablename;
```

---

#### T1.7: Backend middleware (Day 4-5, 8 hours)

**New file:** `src/server/middleware/tenantContext.ts`

```typescript
import { Request, Response, NextFunction } from 'express';
import { pool } from '@/lib/database';
import { getSupabaseClient } from '@/lib/supabaseClient';

export async function tenantContextMiddleware(
    req: Request, 
    res: Response, 
    next: NextFunction
) {
    try {
        let traccarTenantId: number | null = null;
        
        // Method 1: From JWT claim (set by auth middleware)
        if (req.user?.tenantId) {
            traccarTenantId = req.user.tenantId;
        }
        
        // Method 2: From subdomain → lookup in Traccar
        else if (req.hostname !== 'gps.bellerox.com') {
            const subdomain = req.hostname.split('.')[0];
            
            const result = await pool.query(
                'SELECT id FROM tenants WHERE slug = $1',
                [subdomain]
            );
            
            if (result.rows.length > 0) {
                traccarTenantId = result.rows[0].id;
            }
        }
        
        // Method 3: From custom domain → lookup in Supabase cl_tenants
        else {
            const supabase = getSupabaseClient();
            const { data } = await supabase
                .from('cl_tenants')
                .select('data')
                .eq('domain', req.hostname)
                .maybeSingle();
            
            if (data?.data?.traccar_tenant_id) {
                traccarTenantId = parseInt(data.data.traccar_tenant_id);
            }
        }
        
        if (!traccarTenantId) {
            return res.status(400).json({ error: 'Tenant not found' });
        }
        
        // Set PostgreSQL session variable (RLS uses this)
        await pool.query('SET LOCAL app.current_tenant = $1', [traccarTenantId]);
        
        req.tenantId = traccarTenantId;
        next();
    } catch (err) {
        console.error('[Tenant Context] Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
}
```

**Apply globally:**
```typescript
// src/server/index.ts
app.use('/api', authMiddleware);          // 1. Authenticate
app.use('/api', tenantContextMiddleware); // 2. Set tenant context
app.use('/api', routes);                  // 3. Handle routes
```

---

### Part 2: Supabase Integration (3 days)

**Goal:** Sync tenant IDs, use Supabase for config/billing

#### T2.1: Update cl_tenants schema (Day 6, 2 hours)

**Supabase SQL Editor:**

```sql
-- Add traccar_tenant_id to cl_tenants.data JSONB
UPDATE cl_tenants 
SET data = jsonb_set(
    COALESCE(data, '{}'::jsonb),
    '{traccar_tenant_id}',
    '1'::jsonb
)
WHERE slug = 'gpsthailand';

-- Verify
SELECT 
    id,
    slug,
    domain,
    data->>'traccar_tenant_id' AS traccar_tenant_id
FROM cl_tenants;
```

Expected output:
```
id: e5aa2528-adc8-4a45-a742-9f851870862d
slug: gpsthailand
domain: gpsthailand.centerlink.co.th
traccar_tenant_id: 1
```

---

#### T2.2: Tenant service hybrid (Day 6-7, 6 hours)

**Update:** `src/services/tenantService.ts`

```typescript
// Add sync function
export async function syncTenantToSupabase(
    traccarTenantId: number,
    slug: string,
    name: string
): Promise<string> {
    const supabase = getSupabaseClient();
    
    // Check if already exists
    const { data: existing } = await supabase
        .from('cl_tenants')
        .select('id')
        .eq('slug', slug)
        .maybeSingle();
    
    if (existing) {
        // Update traccar_tenant_id
        await supabase
            .from('cl_tenants')
            .update({
                data: {
                    traccar_tenant_id: traccarTenantId,
                    name
                }
            })
            .eq('id', existing.id);
        
        return existing.id;
    }
    
    // Create new
    const { data: newTenant } = await supabase
        .from('cl_tenants')
        .insert({
            slug,
            domain: null,
            status: 'active',
            data: {
                traccar_tenant_id: traccarTenantId,
                name,
                theme: {
                    primaryColor: '#1E40AF',
                    secondaryColor: '#3B82F6'
                }
            }
        })
        .select()
        .single();
    
    return newTenant.id;
}

// Fetch tenant config (from Supabase)
export async function getTenantConfig(traccarTenantId: number) {
    const supabase = getSupabaseClient();
    
    const { data } = await supabase
        .from('cl_tenants')
        .select('*')
        .filter('data->>traccar_tenant_id', 'eq', traccarTenantId.toString())
        .maybeSingle();
    
    if (!data) return null;
    
    return {
        id: traccarTenantId,
        supabaseId: data.id,
        slug: data.slug,
        domain: data.domain,
        config: data.data || {},
        status: data.status
    };
}
```

---

#### T2.3: Admin tenant management (Day 8, 4 hours)

**New file:** `src/pages/admin/TenantsPage.tsx`

```typescript
export function TenantsPage() {
    const { data: tenants, isLoading } = useQuery({
        queryKey: ['admin', 'tenants'],
        queryFn: async () => {
            // Fetch from Traccar DB
            const res = await fetch('/api/admin/tenants');
            return res.json();
        }
    });
    
    const createMutation = useMutation({
        mutationFn: async (data: { slug: string; name: string }) => {
            const res = await fetch('/api/admin/tenants', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
            return res.json();
        }
    });
    
    return (
        <div className="p-6">
            <h1 className="text-2xl font-bold mb-4">Tenants</h1>
            
            <table className="w-full border">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Slug</th>
                        <th>Name</th>
                        <th>Devices</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {tenants?.map(t => (
                        <tr key={t.id}>
                            <td>{t.id}</td>
                            <td>{t.slug}</td>
                            <td>{t.name}</td>
                            <td>{t.device_count}</td>
                            <td>
                                <button>Edit</button>
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}
```

---

#### T2.4: Billing integration (Day 9, 4 hours)

**Update:** `src/services/billingService.ts`

Add tenant_id to subscription:

```typescript
async upsertSubscription(row: Omit<BillingSubscriptionRow, 'created_at' | 'updated_at'>) {
    if (!isSupabaseReady()) return;
    
    // Get Supabase tenant ID from Traccar tenant ID
    const supabase = getSupabaseClient();
    const { data: tenant } = await supabase
        .from('cl_tenants')
        .select('id')
        .filter('data->>traccar_tenant_id', 'eq', row.tenant_id)
        .single();
    
    if (!tenant) {
        throw new Error(`Tenant ${row.tenant_id} not found in Supabase`);
    }
    
    // Use Supabase UUID for tenant_id
    await supabase.from('billing_subscriptions').upsert({
        ...row,
        tenant_id: tenant.id,
        updated_at: new Date().toISOString()
    }, { onConflict: 'tenant_id,device_id' });
}
```

---

#### T2.5: Testing & Verification (Day 10, 4 hours)

**Test 1: Create second tenant**
```sql
-- Traccar DB
INSERT INTO tenants (id, slug, name) VALUES 
    (2, 'demo-fleet', 'Demo Fleet Company');

-- Supabase (via API)
POST /api/admin/tenants
{
  "slug": "demo-fleet",
  "name": "Demo Fleet Company"
}
```

**Test 2: Assign device to tenant 2**
```sql
UPDATE tc_devices SET tenant_id = 2 WHERE id = 100;
```

**Test 3: Query as tenant 1**
```sql
SET app.current_tenant = 1;
SELECT * FROM tc_devices; -- Should NOT see device 100
```

**Test 4: Query as tenant 2**
```sql
SET app.current_tenant = 2;
SELECT * FROM tc_devices; -- Should ONLY see device 100
```

**Test 5: Check Supabase sync**
```sql
-- Supabase
SELECT * FROM cl_tenants;
-- Should have 2 tenants with traccar_tenant_id = 1 and 2
```

---

## Success Criteria

- ✅ 2+ tenants running in Traccar DB
- ✅ RLS enforces isolation (cross-tenant queries return 0 rows)
- ✅ Supabase cl_tenants synced with Traccar tenants
- ✅ Query performance < 5ms overhead
- ✅ All existing features still work for tenant 1

---

## Rollback Plan

### If RLS causes issues:

**Step 1: Disable RLS**
```sql
ALTER TABLE tc_devices DISABLE ROW LEVEL SECURITY;
ALTER TABLE tc_users DISABLE ROW LEVEL SECURITY;
```

**Step 2: Remove tenant_id requirement (optional)**
```sql
ALTER TABLE tc_devices ALTER COLUMN tenant_id DROP NOT NULL;
```

---

## Cost Analysis

**Infrastructure:** ฿0 (same VM, same Supabase free tier)

**Time:**
- Part 1: 5 days (Traccar DB)
- Part 2: 3 days (Supabase integration)
- Testing: 2 days
- **Total: 10 days = 2 weeks**

---

**Status:** Ready to execute  
**Next:** Run T1.1 (create tenants table)
