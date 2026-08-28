# 🏢 Bellerox GPS — Realistic Enterprise Plan
# 4,000 Vehicles · 10 Tenants · Zero New Infrastructure

**Status:** draft  
**Created:** 2026-08-26 (revised after reality check)  
**Timeline:** 8-12 weeks  
**Infra Cost:** **฿0** (optimize existing VM)

---

## 🎯 Reality Check

### What We Actually Have (gcloud audit 22 Aug):
- **1× VM:** n2-standard-2 (2 vCPU, 8GB RAM) — **$97/month**
- **Disk:** 50GB SSD
- **DB:** PostgreSQL in Docker (not Cloud SQL)
- **Cache:** No Redis (not needed at 4k vehicles)
- **Load Balancer:** No HAProxy (single Traccar instance enough)
- **Vehicles:** 214 devices, planning for 4,000
- **Tenants:** Currently 1 (GPS Thailand), planning for 10

### What Master Plan Assumed (WRONG):
- ❌ 3× e2-standard-4 VMs = $390/month
- ❌ Cloud SQL = $200/month
- ❌ Redis cluster = $75/month
- ❌ Total: $934/month → **9.6x over real cost!**

---

## 💡 New Strategy: Optimize, Don't Rebuild

**Philosophy:** Make current infra enterprise-ready WITHOUT new servers

**Approach:**
1. **Software-only multi-tenancy** (PostgreSQL RLS + tenant_id)
2. **SSL via Let's Encrypt** (free, auto-renew)
3. **RBAC in application layer** (no IAM service)
4. **Polish existing mobile app** (Expo SDK 51 already deployed)
5. **White-label via config** (no separate instances)

**Result:** Enterprise features at SME cost

---

## 📋 PART 1: IMMEDIATE FIXES (Week 1)

### Phase 0: Rollback Recovery — DLT Cross-Tab Guard

**Problem:** 9f78faf lost in rollback → 429 errors  
**Cost:** ฿0 (code fix only)  
**Time:** 3 hours

#### Tasks (8 tasks — same as before)
- T000.1-T000.8: Restore cross-tab guard from 9f78faf
  - `msUntilNextDltSend()` in dltService
  - Atomic claim in `sendDltBatch`
  - Guard in `useDltAutoSend`
  - 7 test cases

**✓ Done When:** 1 DLT request/min even with 3 tabs

---

## 🏗️ PART 2: MULTI-TENANT CORE (Week 2-3)

### Phase 1: Database Multi-Tenancy (Software-Only)

**Goal:** 10 tenants sharing 1 PostgreSQL instance  
**Cost:** ฿0 (same VM, add tenant_id columns)  
**Time:** 2 weeks

#### Architecture
```
Single PostgreSQL (Docker)
├─ Table: tenants (new)
├─ Table: tc_users (add tenant_id column)
├─ Table: tc_devices (add tenant_id column)
├─ Table: tc_groups (add tenant_id column)
└─ Row-Level Security policies (automatic filtering)
```

#### Schema Migration (Zero Downtime)
```sql
-- Step 1: Add nullable tenant_id
ALTER TABLE tc_users ADD COLUMN tenant_id INT REFERENCES tenants(id);
ALTER TABLE tc_devices ADD COLUMN tenant_id INT REFERENCES tenants(id);
ALTER TABLE tc_groups ADD COLUMN tenant_id INT REFERENCES tenants(id);

-- Step 2: Backfill existing data (tenant_id = 1 for GPS Thailand)
UPDATE tc_users SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE tc_devices SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE tc_groups SET tenant_id = 1 WHERE tenant_id IS NULL;

-- Step 3: Add NOT NULL constraint (after backfill)
ALTER TABLE tc_users ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE tc_devices ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE tc_groups ALTER COLUMN tenant_id SET NOT NULL;

-- Step 4: Row-Level Security
ALTER TABLE tc_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_users ON tc_users
  USING (tenant_id = current_setting('app.current_tenant')::int);

-- Repeat for tc_devices, tc_groups, tc_positions...
```

#### Tasks (18 tasks)

**T1.1-T1.5: Schema Design**
- **T1.1** Design tenant ERD
  - tenants, tenant_users, tenant_devices tables
  - Migration plan (add column → backfill → NOT NULL)

- **T1.2** Create migration scripts
  - `001_create_tenants_table.sql`
  - `002_add_tenant_id_columns.sql`
  - `003_backfill_existing_data.sql`
  - `004_add_not_null_constraints.sql`
  - `005_enable_row_level_security.sql`

- **T1.3** Test on local copy
  - pg_dump production → local DB
  - Run all migrations
  - Verify data integrity
  - Performance test (query plans)

- **T1.4** Deploy migrations (maintenance window 2 AM)
  - Run in transaction (rollback if error)
  - Monitor query performance
  - Verify RLS policies working

- **T1.5** Add indexes for tenant_id
  - `CREATE INDEX idx_users_tenant ON tc_users(tenant_id)`
  - `CREATE INDEX idx_devices_tenant ON tc_devices(tenant_id)`
  - Query plans should use index

**T1.6-T1.10: Backend API**
- **T1.6** Tenant context middleware
  - Extract tenant from JWT claim
  - Set PostgreSQL session variable: `SET app.current_tenant = X`
  - All queries auto-filtered by RLS

- **T1.7** Tenant CRUD API
  - POST /api/admin/tenants (super-admin only)
  - GET /api/admin/tenants
  - PUT /api/admin/tenants/:id
  - Soft delete (mark deleted_at, keep data 90 days)

- **T1.8** Tenant user assignment
  - POST /api/admin/tenants/:id/users
  - DELETE /api/admin/tenants/:id/users/:userId

- **T1.9** Device assignment
  - POST /api/admin/tenants/:id/devices (bulk assign)
  - GET /api/admin/tenants/:id/devices

- **T1.10** Tenant config
  - PUT /api/tenants/:id/config (logo, colors, domain)
  - Stored in tenants.config JSONB column

**T1.11-T1.15: Frontend**
- **T1.11** Tenant detection
  - Check subdomain: `companyA.gps.bellerox.com`
  - Load tenant config from API
  - Store in React Context

- **T1.12** Tenant branding
  - Apply logo, primaryColor from config
  - CSS variables for colors
  - Dynamic favicon

- **T1.13** Tenant-scoped data
  - All API calls include tenant context
  - Filter devices by tenant automatically

- **T1.14** Admin: Tenant management page
  - List tenants
  - Create tenant
  - Assign devices/users

- **T1.15** Admin: Tenant settings
  - Upload logo
  - Set primary color
  - Configure domain

**T1.16-T1.18: Security & Testing**
- **T1.16** Security audit
  - Try to access tenant B data as tenant A user
  - Verify RLS blocks cross-tenant queries
  - Test SQL injection with tenant_id

- **T1.17** Performance test
  - 10 tenants, 400 devices each
  - Query latency < 10ms overhead
  - No N+1 queries

- **T1.18** Documentation
  - Tenant onboarding guide
  - Security model diagram
  - API reference

**✓ Done When:**
- 10 tenants running
- No cross-tenant data leaks (pen test)
- Query performance unchanged
- Tenant admin can manage their own data

**Cost:** ฿0 (same VM)

---

## 🔒 PART 3: SECURITY (Week 4)

### Phase 2: HTTPS/SSL with Let's Encrypt

**Goal:** Free SSL cert with auto-renewal  
**Cost:** ฿0 (Let's Encrypt is free)  
**Time:** 3 days

#### Tasks (10 tasks)

**T2.1-T2.5: Certbot Setup**
- **T2.1** Install Certbot
  - `apt-get install certbot python3-certbot-nginx`

- **T2.2** Configure DNS
  - Verify `traccar.gps.bellerox.com` → VM IP
  - Open port 80 for HTTP-01 challenge

- **T2.3** Generate cert
  - `certbot --nginx -d traccar.gps.bellerox.com`
  - Test: `curl https://traccar.gps.bellerox.com/api/server`

- **T2.4** Auto-renewal cron
  - `0 0,12 * * * certbot renew --quiet --post-hook "systemctl reload nginx"`

- **T2.5** Test renewal
  - `certbot renew --dry-run`

**T2.6-T2.10: Nginx SSL Config**
- **T2.6** SSL protocols
  - TLS 1.2, 1.3 only
  - Strong ciphers
  - HSTS header

- **T2.7** Redirect HTTP → HTTPS
  - Port 80 → 301 redirect to 443

- **T2.8** Update frontend
  - `VITE_TRACCAR_API_URL=https://api.centerlink.co.th`

- **T2.9** Certificate monitoring
  - Check expiry daily
  - Alert if < 14 days

- **T2.10** Backup cert
  - Copy `/etc/letsencrypt/` to GCS weekly

**✓ Done When:**
- HTTPS working
- Auto-renewal tested (dry-run passes)
- Cert expires in 90 days

**Cost:** ฿0

---

## 👥 PART 4: RBAC (Week 5-6)

### Phase 3: Role-Based Access Control

**Goal:** 7 roles with granular permissions  
**Cost:** ฿0 (application-layer RBAC)  
**Time:** 2 weeks

#### Roles
1. **Super Admin** — platform owner (Bellerox team)
2. **Tenant Admin** — company owner
3. **Fleet Manager** — operations
4. **Supervisor** — field manager (group-scoped)
5. **Driver** — view own vehicle only
6. **API User** — read-only programmatic
7. **Auditor** — compliance/security

#### Permission Model
```
Resource:Action format
- vehicles:read, vehicles:write, vehicles:delete
- geofences:read, geofences:write
- reports:read, reports:export
- users:read, users:write
- billing:read, billing:write
- audit:read
```

#### Database Schema (Lightweight)
```sql
CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE,
  permissions JSONB -- e.g. ["vehicles:read", "reports:read"]
);

CREATE TABLE user_roles (
  user_id INT REFERENCES tc_users(id),
  role_id INT REFERENCES roles(id),
  scope JSONB, -- e.g. {"groupIds": [1,2,3]} for supervisor
  PRIMARY KEY (user_id, role_id)
);

CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  tenant_id INT,
  user_id INT,
  action VARCHAR(100),
  resource VARCHAR(50),
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Tasks (20 tasks)

**T3.1-T3.5: Schema & Seed**
- T3.1-T3.5: Create RBAC tables, seed 7 roles, assign permissions

**T3.6-T3.10: Middleware**
- T3.6-T3.10: Permission check middleware, cached permissions, audit logging

**T3.11-T3.15: Backend API**
- T3.11-T3.15: Role management, user role assignment, audit log API

**T3.16-T3.20: Frontend UI**
- T3.16-T3.20: Permission hooks, conditional rendering, role-based nav

**✓ Done When:**
- All endpoints protected
- Frontend hides/shows based on permissions
- Audit logs working

**Cost:** ฿0

---

## 📱 PART 5: MOBILE APP (Week 7)

### Phase 4: Polish Existing Mobile App

**Current State:** Expo SDK 51, React Native, expo-router  
**Location:** `/Users/macbookaair/Documents/bellerox_workspace/gps_thailand_application/bellerox-gps-mobile`  
**Goal:** Production-ready mobile experience  
**Cost:** ฿0 (polish existing code)  
**Time:** 1 week

#### What's Already There
```
bellerox-gps-mobile/
├── app/
│   ├── (auth)/login.tsx
│   └── (tabs)/
│       ├── index.tsx        # Live map
│       ├── fleet.tsx        # Vehicle list
│       ├── alerts.tsx       # Alerts
│       └── profile.tsx      # User profile
├── src/services/traccarMobileService.ts
├── src/stores/authStore.ts
├── app.json, eas.json       # Expo config
└── package.json
```

#### Tasks (12 tasks)

**T4.1-T4.5: Core Features**
- **T4.1** Offline mode (IndexedDB cache)
  - Cache last 100 positions per vehicle
  - Sync when reconnected
  - Show "offline" badge

- **T4.2** Push notifications (Expo Notifications)
  - Register device token
  - Backend sends via Expo API
  - Handle: geofence, overspeed, offline

- **T4.3** Dark mode support
  - Follow system theme
  - Persistent user preference

- **T4.4** Thai localization
  - All labels in Thai
  - Distance/speed in km/h
  - Date format: วัน/เดือน/ปี

- **T4.5** Performance optimization
  - Lazy load vehicle list (FlatList)
  - Memoize map markers
  - Reduce re-renders

**T4.6-T4.10: UX Polish**
- **T4.6** Loading states (skeleton screens)
- **T4.7** Error handling (retry button)
- **T4.8** Empty states (no vehicles)
- **T4.9** Pull-to-refresh
- **T4.10** Haptic feedback (vibration on tap)

**T4.11-T4.12: Deployment**
- **T4.11** Build production APK/IPA
  - `eas build --platform all --profile production`
  - Sign with production keys

- **T4.12** Over-The-Air (OTA) updates
  - `eas update --branch production`
  - Update without app store

**✓ Done When:**
- App works offline
- Push notifications working
- Production build uploaded to stores

**Cost:** ฿0 (Expo free tier)

---

## 🎨 PART 6: WHITE-LABEL (Week 8-9)

### Phase 5: Custom Domains & Branding

**Goal:** Resellers use their own domain  
**Cost:** ฿0 (CNAME + config only)  
**Time:** 2 weeks

#### Architecture (No New Servers)
```
Reseller: gps.resellerA.com (CNAME → gps.bellerox.com)
    ├─ Nginx virtual host (detect domain)
    ├─ Load tenant config (logo, colors)
    └─ Apply branding to frontend
```

#### Tasks (15 tasks)

**T5.1-T5.5: Custom Domain Support**
- **T5.1** Nginx multi-domain routing
  - Virtual host per domain
  - Map domain → tenant_id

- **T5.2** SSL per domain
  - Certbot multi-domain
  - `certbot -d gps.bellerox.com -d gps.resellerA.com`

- **T5.3** Domain verification
  - Admin enters domain in settings
  - Verify CNAME record before activation

- **T5.4** DNS check API
  - Check if CNAME points to Bellerox
  - Show verification status in UI

- **T5.5** Domain mapping table
```sql
CREATE TABLE custom_domains (
  id SERIAL PRIMARY KEY,
  tenant_id INT REFERENCES tenants(id),
  domain VARCHAR(255) UNIQUE,
  verified BOOLEAN DEFAULT false
);
```

**T5.6-T5.10: Branding**
- **T5.6** Logo upload API
  - Store in GCS (or local /uploads/)
  - Max 2MB PNG/SVG

- **T5.7** Theme config
  - primaryColor, secondaryColor
  - Store in tenants.config JSONB

- **T5.8** Frontend theme injection
  - CSS variables from config
  - Swap logo in header

- **T5.9** Email white-label
  - Alert emails use reseller logo
  - From: `noreply@resellerA.com`

- **T5.10** Mobile app OTA update
  - Per-tenant splash screen
  - Dynamic app icon (expo-updates)

**T5.11-T5.15: Reseller Portal**
- **T5.11** Reseller signup form
- **T5.12** Domain setup wizard
- **T5.13** Branding upload UI
- **T5.14** API key generation (for integrations)
- **T5.15** Usage dashboard (vehicles, API calls)

**✓ Done When:**
- 3 resellers with custom domains
- Each has unique branding
- API keys working

**Cost:** ฿0

---

## 📊 SUCCESS METRICS

| Metric | Current | Target | Timeline |
|--------|---------|--------|----------|
| Vehicles | 214 | 4,000 | Month 3 |
| Tenants | 1 | 10 | Month 2 |
| Infrastructure cost | $97/mo | $97/mo | Unchanged ✅ |
| API uptime | 99.5% | 99.9% | Month 2 |
| Mobile app users | 0 | 500 | Month 3 |
| Resellers | 0 | 3 | Month 3 |

---

## 💰 REALISTIC COST BREAKDOWN

| Phase | Labor (weeks) | Cost @ ฿50k/week | Infrastructure | Total |
|-------|---------------|------------------|----------------|-------|
| Phase 0: Rollback | 0.25 | ฿12,500 | ฿0 | ฿12,500 |
| Phase 1: Multi-Tenant | 2 | ฿100,000 | ฿0 | ฿100,000 |
| Phase 2: HTTPS/SSL | 0.5 | ฿25,000 | ฿0 | ฿25,000 |
| Phase 3: RBAC | 2 | ฿100,000 | ฿0 | ฿100,000 |
| Phase 4: Mobile Polish | 1 | ฿50,000 | ฿0 | ฿50,000 |
| Phase 5: White-Label | 2 | ฿100,000 | ฿0 | ฿100,000 |
| **TOTAL** | **7.75 weeks** | **฿387,500** | **฿0** | **฿387,500** |

**Infrastructure:** ฿0 (zero new servers, same $97/month VM)

---

## 🎯 Why This Plan is Better

| Old Plan (Wrong) | New Plan (Reality-Based) |
|------------------|--------------------------|
| ❌ 3× VMs ($390/mo) | ✅ Same 1× VM ($97/mo) |
| ❌ Cloud SQL ($200/mo) | ✅ Docker Postgres (included) |
| ❌ Redis cluster ($75/mo) | ✅ No Redis needed (4k vehicles) |
| ❌ HAProxy load balancer | ✅ Single Traccar instance enough |
| ❌ 36 weeks, ฿2.1M | ✅ 8 weeks, ฿387k |
| ❌ 20k vehicles (fantasy) | ✅ 4k vehicles (realistic) |
| ❌ New mobile app | ✅ Polish existing app |

**Savings:** ฿1.7M (82% cheaper!)

---

## 📋 Execution Order

**Week 1:** Phase 0 (DLT fix) — critical bug  
**Week 2-3:** Phase 1 (Multi-tenant) — foundation  
**Week 4:** Phase 2 (HTTPS) — security  
**Week 5-6:** Phase 3 (RBAC) — permissions  
**Week 7:** Phase 4 (Mobile) — polish app  
**Week 8-9:** Phase 5 (White-label) — reseller channel

**Total: 9 weeks, ฿387,500, ฿0 infrastructure**

---

**End of Realistic Plan**

**Next Step:** Review Phase 0 (DLT Rollback Recovery) or start immediately?