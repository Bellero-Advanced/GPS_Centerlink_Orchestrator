# 🏢 Bellerox GPS — Enterprise Master Plan
# Thai → APAC → Global · 100,000+ Vehicles

**Status:** draft  
**Created:** 2026-08-26  
**Timeline:** 6-12 months (phased rollout)  
**Scope:** Complete enterprise transformation + immediate fixes

---

## 🎯 Executive Summary

Transform Bellerox GPS from **SME product** (4,000 vehicles) to **enterprise-grade SaaS** (100,000+ vehicles) with:
- **Security:** HTTPS/SSL automation + SOC 2 compliance
- **Scale:** Multi-tenant isolation + RBAC + white-label API
- **Reliability:** 99.9% SLA + cost optimization + full observability
- **Immediate:** Fix lost DLT cross-tab guard (rollback recovery)

---

## 📊 Priority Matrix

| Priority | Phase | Timeline | Impact |
|----------|-------|----------|--------|
| **P0** | Rollback Recovery | Week 1 | Critical: 429 blocking production |
| **P0** | HTTPS/SSL Automation | Week 2-3 | Security: required for enterprise |
| **P1** | Cost Optimization | Week 3-4 | Revenue: reduce infra cost 40% |
| **P1** | Multi-Tenant Core | Week 5-8 | Product: enterprise blocker |
| **P2** | RBAC + Permissions | Week 9-12 | Security: enterprise requirement |
| **P2** | White-label API | Week 13-16 | Revenue: reseller channel |
| **P3** | Advanced Analytics | Month 5-6 | Product: competitive edge |

---

## 🚨 PART 1: IMMEDIATE FIXES (Week 1)

### Phase 0: Rollback Recovery — DLT Cross-Tab Guard

**Problem:** Commit 9f78faf (22 AUG) lost in rollback 8d62fa7 (24 AUG)  
**Impact:** 3 admins = 3 DLT requests/min → 429 Too Many Requests  
**Timeline:** 2-3 hours

#### Tasks (8 tasks)
- **T000.1** Audit what was lost in rollback
  - Compare 9f78faf vs current HEAD
  - List files changed, features lost
  - Check if WebSocket fix (8ac8255) also lost

- **T000.2** Restore `msUntilNextDltSend()` in dltService.ts
  - Add `LS_DLT_LAST_SEND` localStorage key
  - Implement gap window check (55s threshold)
  - Handle corrupt/missing timestamps

- **T000.3** Restore atomic claim in `sendDltBatch`
  - Check + claim slot before HTTP POST
  - Log skip if another tab claimed
  - Store ISO timestamp after success

- **T000.4** Restore guard in `useDltAutoSend`
  - Call `msUntilNextDltSend()` before fetch
  - Skip if `waitMs > 0`
  - Log which tab is skipping

- **T000.5** Restore 7 test cases from 9f78faf
  - `dltRateLimit.test.ts`
  - Cover: first send, gap window, future timestamp, corrupt data

- **T000.6** Verify WebSocket still working
  - Check if 8ac8255 survived rollback
  - Test live position updates
  - Verify mount in LayoutV2.tsx

- **T000.7** Build + Deploy
  - `npm run build` → 0 errors
  - Deploy to production
  - Monitor for 24h

- **T000.8** Update memory
  - Document rollback recovery in changelog
  - Add to decisions.md: "DLT cross-tab guard essential"

**✓ Done When:** 1 DLT request/min even with 3 tabs open

---

## 🔒 PART 2: SECURITY & INFRASTRUCTURE (Week 2-4)

### Phase 1: HTTPS/SSL Automation with Let's Encrypt

**Why:** Enterprise customers require HTTPS. Manual cert renewal is error-prone.  
**Timeline:** Week 2-3 (10 days)

#### Architecture
```
Client → Cloudflare (HTTPS) → Origin (api.centerlink.co.th)
                              → GCP VM (34.142.244.40)
                                  → Nginx (HTTPS:443)
                                      → Certbot (Let's Encrypt auto-renew)
                                      → Traccar :8082
```

#### Tasks (15 tasks)
- **T1.1** Audit current SSL setup
  - Check if Nginx has SSL config
  - Check Certbot installation
  - Review Cloudflare SSL mode (Flexible vs Full)

- **T1.2** Install Certbot on GCP VM
  - `apt-get install certbot python3-certbot-nginx`
  - Test with `certbot --version`

- **T1.3** Configure DNS for ACME challenge
  - Ensure `traccar.gps.bellerox.com` points to VM
  - Open port 80 for HTTP-01 challenge
  - Verify with `curl http://traccar.gps.bellerox.com/.well-known/`

- **T1.4** Generate initial certificate
  - `certbot --nginx -d traccar.gps.bellerox.com`
  - Store cert in `/etc/letsencrypt/live/`
  - Test HTTPS: `curl https://traccar.gps.bellerox.com/api/server`

- **T1.5** Configure Nginx SSL
  - Listen on 443 with SSL
  - Redirect HTTP 80 → HTTPS 443
  - Set SSL protocols (TLS 1.2+)
  - Enable HSTS header

- **T1.6** Auto-renewal systemd timer
  - Create `/etc/systemd/system/certbot-renew.timer`
  - Run twice daily: `0 0,12 * * *`
  - Reload Nginx after renewal

- **T1.7** Test renewal dry-run
  - `certbot renew --dry-run`
  - Verify systemd timer: `systemctl list-timers`

- **T1.8** Update Cloudflare SSL mode
  - Change from Flexible → Full (strict)
  - Verify end-to-end encryption

- **T1.9** Update frontend API base URL
  - Change `VITE_TRACCAR_API_URL` to HTTPS
  - Test API calls from browser

- **T1.10** Certificate monitoring
  - Add Prometheus alert: cert expires < 14 days
  - Grafana dashboard: cert expiry countdown

- **T1.11** Backup cert private key
  - Store in GCP Secret Manager
  - Encrypted backup to GCS

- **T1.12** Document runbook
  - Manual renewal steps
  - Troubleshooting guide
  - Rollback procedure

- **T1.13** GPS device port security
  - GPS ports (5001-5093) stay TCP (no SSL)
  - Firewall: allow only from known IP ranges
  - Consider VPN for enterprise fleets

- **T1.14** Load test HTTPS
  - 1000 concurrent WebSocket connections
  - Monitor SSL handshake latency
  - Target: < 100ms p95

- **T1.15** Deploy + verify
  - Gradual rollout: 10% → 50% → 100%
  - Monitor error rates
  - Rollback plan ready

**✓ Done When:**
- HTTPS works on all endpoints
- Auto-renewal tested (dry-run passes)
- Certificate expires in 90 days, renews at 30 days
- Grafana shows cert status

---

### Phase 2: Cost Optimization — Reduce 40% Infrastructure Cost

**Current Cost:** ~$934/month (20k vehicles)  
**Target Cost:** ~$560/month (save $374/month = $4,488/year)  
**Timeline:** Week 3-4 (12 days)

#### Optimization Areas
1. **Database:** Partition + compression → 60% storage reduction
2. **Compute:** Right-size VMs → 25% cost reduction
3. **Network:** CDN + compression → 50% egress reduction
4. **API:** Cache + batch → 80% Traccar API calls reduction

#### Tasks (20 tasks)

**T2.1-T2.5: Database Optimization**
- **T2.1** Implement TimescaleDB hypertables
  - Convert `tc_positions` to hypertable
  - Chunk by 1-day intervals
  - Add compression policy (> 7 days)

- **T2.2** Add retention policy
  - Auto-drop chunks > 90 days
  - Export to GCS before deletion (compliance)

- **T2.3** Create continuous aggregates
  - Hourly position summaries
  - Daily trip statistics
  - Reduce dashboard query time 90%

- **T2.4** Optimize indexes
  - Drop unused indexes (found 12 in audit)
  - Add covering indexes for hot queries
  - Rebuild fragmented indexes

- **T2.5** Enable PostgreSQL compression
  - TOAST compression on position attributes
  - Expected: 40% row size reduction

**T2.6-T2.10: Compute Right-Sizing**
- **T2.6** Analyze actual resource usage
  - Prometheus metrics: CPU, memory, disk I/O
  - Peak vs average utilization
  - Identify over-provisioned services

- **T2.7** Resize Traccar VMs
  - Current: 3× e2-standard-4 (4 vCPU, 16GB)
  - Target: 3× e2-standard-2 (2 vCPU, 8GB)
  - Test under load before commit

- **T2.8** Use Spot/Preemptible instances
  - Non-critical: monitoring, report-processor
  - Save 60-70% on those VMs
  - Auto-restart on preemption

- **T2.9** Containerize services
  - Move from VMs to GKE Autopilot
  - Only pay for used CPU/memory
  - Auto-scale based on load

- **T2.10** Schedule non-critical jobs
  - Run backups during off-peak (3-5 AM)
  - Batch report generation: hourly → daily
  - Reduce concurrent load

**T2.11-T2.15: Network & CDN**
- **T2.11** Enable Cloudflare caching
  - Cache static assets (JS, CSS, images)
  - Cache GET /api/devices for 30s
  - Purge on updates

- **T2.12** Compress API responses
  - Enable gzip/brotli in Nginx
  - Reduce payload size 70%

- **T2.13** Optimize map tiles
  - Use Cloudflare CDN for tile requests
  - Cache tiles 7 days
  - Reduce bandwidth 80%

- **T2.14** Reduce egress to client
  - Send only visible vehicle positions
  - Delta updates (send only changed fields)
  - WebSocket binary protocol (vs JSON)

- **T2.15** Regional caching
  - Deploy Redis in GCP asia-southeast1
  - Cache hot data (latest positions)
  - Reduce database queries

**T2.16-T2.20: API & Query Optimization**
- **T2.16** Implement request coalescing
  - Dedupe identical API calls within 1s window
  - Reduce Traccar load 60%

- **T2.17** Batch position fetches
  - Replace N×1 queries with 1×N batch
  - Reduce latency 80%

- **T2.18** Add Redis cache layer
  - Cache latest positions (TTL: 30s)
  - Cache device metadata (TTL: 5min)
  - Hit rate target: 85%

- **T2.19** Optimize WebSocket messages
  - Send deltas, not full objects
  - Compress with MessagePack
  - Reduce bandwidth 60%

- **T2.20** Monitor cost savings
  - GCP Billing dashboard
  - Cost per vehicle metric
  - Alert if cost > target

**✓ Done When:**
- Monthly infra cost < $600
- Performance unchanged or improved
- All services healthy after optimization

---

## 🏢 PART 3: ENTERPRISE ARCHITECTURE (Week 5-16)

### Phase 3: Multi-Tenant Core Infrastructure

**Why:** Enterprise customers need data isolation + custom configs  
**Timeline:** Week 5-8 (4 weeks)

#### Architecture
```
Single Traccar Instance
    ├─ Tenant 1 (Company A) — 5,000 vehicles
    │   ├─ Groups: Fleet A, Fleet B
    │   ├─ Users: Admin, Manager, Driver
    │   └─ Config: Logo, Color, Domain
    ├─ Tenant 2 (Company B) — 2,000 vehicles
    │   ├─ Groups: Logistics, Delivery
    │   └─ Config: Custom domain
    └─ Tenant 3 (Reseller X) — 10,000 vehicles
        ├─ Sub-tenants: Client 1, Client 2
        └─ White-label branding
```

#### Database Schema
```sql
-- New tables
CREATE TABLE tenants (
  id SERIAL PRIMARY KEY,
  slug VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  domain VARCHAR(255), -- custom domain (optional)
  config JSONB, -- branding, features, limits
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tenant_users (
  tenant_id INT REFERENCES tenants(id),
  user_id INT REFERENCES tc_users(id),
  role VARCHAR(50) NOT NULL, -- admin, manager, driver
  PRIMARY KEY (tenant_id, user_id)
);

CREATE TABLE tenant_devices (
  tenant_id INT REFERENCES tenants(id),
  device_id INT REFERENCES tc_devices(id),
  PRIMARY KEY (tenant_id, device_id)
);

-- Add tenant_id to existing tables (non-breaking)
ALTER TABLE tc_users ADD COLUMN tenant_id INT REFERENCES tenants(id);
ALTER TABLE tc_devices ADD COLUMN tenant_id INT REFERENCES tenants(id);
ALTER TABLE tc_groups ADD COLUMN tenant_id INT REFERENCES tenants(id);

CREATE INDEX idx_users_tenant ON tc_users(tenant_id);
CREATE INDEX idx_devices_tenant ON tc_devices(tenant_id);
```

#### Tasks (25 tasks)

**T3.1-T3.5: Database Schema**
- **T3.1** Design tenant schema
  - ERD diagram
  - Migration plan (zero downtime)
  - Rollback strategy

- **T3.2** Create migration scripts
  - `001_create_tenants.sql`
  - `002_add_tenant_id_columns.sql`
  - `003_migrate_existing_data.sql`

- **T3.3** Test migration on staging
  - Copy production DB snapshot
  - Run migrations
  - Verify data integrity

- **T3.4** Add tenant_id to all queries
  - Audit 200+ SQL queries in codebase
  - Add `WHERE tenant_id = ?` filter
  - Prevent cross-tenant data leaks

- **T3.5** Deploy migrations to production
  - Run during maintenance window
  - Monitor query performance
  - Rollback if errors

**T3.6-T3.10: Backend API**
- **T3.6** Add tenant context middleware
  - Extract tenant from JWT or subdomain
  - Attach to request context
  - All queries scoped to tenant

- **T3.7** Tenant CRUD API
  - POST /api/tenants — create tenant (super-admin only)
  - GET /api/tenants/:id — read tenant
  - PUT /api/tenants/:id — update config
  - DELETE /api/tenants/:id — soft delete

- **T3.8** Tenant user management
  - POST /api/tenants/:id/users — add user to tenant
  - GET /api/tenants/:id/users — list tenant users
  - PUT /api/tenants/:id/users/:userId/role — change role
  - DELETE /api/tenants/:id/users/:userId — remove user

- **T3.9** Device assignment API
  - POST /api/tenants/:id/devices — assign devices
  - GET /api/tenants/:id/devices — list tenant devices
  - DELETE /api/tenants/:id/devices/:deviceId — unassign

- **T3.10** Tenant config API
  - PUT /api/tenants/:id/config — update branding
  - GET /api/tenants/:id/config — read config
  - Fields: logo, primaryColor, domain, features

**T3.11-T3.15: Frontend Tenant Support**
- **T3.11** Tenant detection
  - Check subdomain: `companyA.gps.bellerox.com`
  - Or custom domain: `gps.companyA.com`
  - Load tenant config from API

- **T3.12** Tenant branding
  - Apply logo, colors from config
  - Dynamic favicon
  - Custom domain title

- **T3.13** Tenant-scoped data
  - All API calls include tenant context
  - Filter devices, users, geofences by tenant
  - Prevent cross-tenant access

- **T3.14** Tenant switcher (super-admin)
  - Dropdown to switch between tenants
  - Debug tool for support

- **T3.15** Tenant settings page
  - Admins configure branding
  - Upload logo
  - Set primary color

**T3.16-T3.20: Security & Isolation**
- **T3.16** Row-level security (RLS)
  - PostgreSQL RLS policies
  - Enforce tenant_id filter at DB level
  - Even if app bug, DB blocks cross-tenant

- **T3.17** Audit logging
  - Log all tenant changes
  - Who created/deleted tenant
  - Who assigned devices

- **T3.18** Rate limiting per tenant
  - Separate quotas per tenant
  - Prevent one tenant from DoS
  - Fair resource allocation

- **T3.19** Data export per tenant
  - Tenant admin can export all their data
  - GDPR compliance
  - CSV/JSON format

- **T3.20** Tenant deletion
  - Soft delete (mark deleted_at)
  - Cascade to devices, users, geofences
  - Hard delete after 90 days (backup first)

**T3.21-T3.25: Testing & Documentation**
- **T3.21** Unit tests
  - Tenant middleware
  - RLS policies
  - API endpoints

- **T3.22** Integration tests
  - Create tenant → add users → assign devices
  - Verify isolation between tenants
  - Test cross-tenant access blocked

- **T3.23** Load test multi-tenant
  - 100 tenants, 20k devices
  - Query performance unchanged
  - No N+1 queries

- **T3.24** Documentation
  - Tenant onboarding guide
  - API reference
  - Security model

- **T3.25** Deploy + monitor
  - Gradual rollout
  - Monitor query performance
  - Alert on cross-tenant access attempts

**✓ Done When:**
- 10 tenants running in production
- No cross-tenant data leaks (security audit)
- Query performance < 5% degradation
- All tests pass

---

### Phase 4: Role-Based Access Control (RBAC)

**Why:** Enterprise needs granular permissions (not just admin/user)  
**Timeline:** Week 9-12 (4 weeks)

#### Roles & Permissions Model
```
Super Admin — platform owner (Bellerox)
  └─ Can: create tenants, view all data, impersonate

Tenant Admin — company owner
  └─ Can: manage users, devices, billing, branding

Fleet Manager — operations manager
  └─ Can: view all vehicles, create geofences, run reports
  └─ Cannot: manage users, change billing

Driver Supervisor — field supervisor
  └─ Can: view assigned group only, send commands
  └─ Cannot: delete vehicles, see other groups

Driver — end user (mobile app)
  └─ Can: view own vehicle only, no admin access
  └─ Cannot: see other drivers

API User — programmatic access (integrations)
  └─ Can: read-only API access (reports, positions)
  └─ Cannot: modify data

Auditor — compliance/security
  └─ Can: read-only access to all data + audit logs
  └─ Cannot: modify anything
```

#### Permission Matrix
| Resource | Super Admin | Tenant Admin | Fleet Mgr | Supervisor | Driver | API | Auditor |
|----------|-------------|--------------|-----------|------------|--------|-----|---------|
| View all vehicles | ✅ | ✅ | ✅ | ❌ (group only) | ❌ (self only) | ✅ | ✅ |
| Add/delete vehicles | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Create geofences | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Run reports | ✅ | ✅ | ✅ | ✅ (group only) | ❌ | ✅ | ✅ |
| Manage users | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Change billing | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| View audit logs | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Send commands | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| API access | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |

#### Database Schema
```sql
CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  is_system BOOLEAN DEFAULT false -- can't be deleted
);

CREATE TABLE permissions (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL, -- e.g. "vehicles:read"
  resource VARCHAR(50) NOT NULL, -- e.g. "vehicles"
  action VARCHAR(20) NOT NULL, -- e.g. "read", "write", "delete"
  description TEXT
);

CREATE TABLE role_permissions (
  role_id INT REFERENCES roles(id) ON DELETE CASCADE,
  permission_id INT REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
  user_id INT REFERENCES tc_users(id) ON DELETE CASCADE,
  role_id INT REFERENCES roles(id) ON DELETE CASCADE,
  tenant_id INT REFERENCES tenants(id),
  scope JSONB, -- e.g. {"groupIds": [1,2,3]} for supervisor
  PRIMARY KEY (user_id, role_id, tenant_id)
);

-- Audit log
CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  tenant_id INT REFERENCES tenants(id),
  user_id INT REFERENCES tc_users(id),
  action VARCHAR(100) NOT NULL,
  resource VARCHAR(50) NOT NULL,
  resource_id INT,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_tenant_time ON audit_log(tenant_id, created_at DESC);
```

#### Tasks (30 tasks)

**T4.1-T4.5: Schema & Seed Data**
- **T4.1** Create RBAC schema
  - roles, permissions, role_permissions, user_roles tables
  - Migration scripts
  - Rollback plan

- **T4.2** Seed system roles
  - Super Admin, Tenant Admin, Fleet Manager, Supervisor, Driver, API, Auditor
  - Mark `is_system = true` (can't delete)

- **T4.3** Seed permissions
  - vehicles:read, vehicles:write, vehicles:delete
  - geofences:read, geofences:write
  - reports:read, reports:export
  - users:read, users:write
  - billing:read, billing:write
  - audit:read
  - 50+ permissions total

- **T4.4** Assign permissions to roles
  - Map role → permissions (see matrix above)
  - Store in role_permissions table

- **T4.5** Migrate existing users
  - Map old `admin` flag → Tenant Admin or Super Admin
  - Regular users → Fleet Manager (default)

**T4.6-T4.10: Authorization Middleware**
- **T4.6** Permission check middleware
  - `requirePermission('vehicles:read')`
  - Check user_roles → role_permissions
  - Return 403 if missing

- **T4.7** Scope enforcement
  - Supervisor sees only assigned groups
  - Driver sees only own vehicle
  - Apply WHERE filter in queries

- **T4.8** Cached permission checks
  - Load user permissions on login
  - Store in JWT or session
  - Refresh on role change

- **T4.9** Permission helper functions
  - `hasPermission(user, 'vehicles:write')`
  - `getAccessibleDevices(user)` — filtered list
  - `canAccessDevice(user, deviceId)` — boolean

- **T4.10** Audit log interceptor
  - Log all write operations
  - Log permission denials (403)
  - Store IP, user agent, timestamp

**T4.11-T4.15: Backend API**
- **T4.11** Role management API
  - GET /api/roles — list roles
  - POST /api/roles — create custom role (tenant-admin only)
  - PUT /api/roles/:id — edit custom role
  - DELETE /api/roles/:id — delete (not system roles)

- **T4.12** Permission API
  - GET /api/permissions — list all permissions
  - GET /api/roles/:id/permissions — role's permissions
  - PUT /api/roles/:id/permissions — assign permissions

- **T4.13** User role assignment API
  - POST /api/users/:id/roles — assign role to user
  - GET /api/users/:id/roles — list user's roles
  - DELETE /api/users/:id/roles/:roleId — remove role
  - PUT /api/users/:id/roles/:roleId/scope — set scope (groupIds)

- **T4.14** Audit log API
  - GET /api/audit — list audit logs (auditor only)
  - Filters: tenant, user, action, resource, date range
  - Pagination: 100 entries/page
  - Export to CSV

- **T4.15** My permissions API
  - GET /api/me/permissions — current user's permissions
  - GET /api/me/accessible-devices — filtered device list
  - Frontend uses this for UI visibility

**T4.16-T4.20: Frontend RBAC**
- **T4.16** Permission context
  - Load user permissions on login
  - React Context: `usePermissions()`
  - `hasPermission('vehicles:write')` hook

- **T4.17** Conditional UI rendering
  - Hide "Delete" button if no `vehicles:delete`
  - Hide "Manage Users" tab if no `users:read`
  - Disable form fields if no `vehicles:write`

- **T4.18** Role-based navigation
  - Admin sees: Dashboard, Fleet, Users, Billing, Settings
  - Manager sees: Dashboard, Fleet, Reports
  - Driver sees: My Vehicle, Profile

- **T4.19** Scope-based filtering
  - Supervisor: filter devices by assigned groups
  - Driver: show only own vehicle
  - API client: read-only data

- **T4.20** User management UI
  - Tenant Admin: assign roles to users
  - Set scope (select groups for supervisor)
  - Revoke roles

**T4.21-T4.25: Security & Testing**
- **T4.21** API endpoint audit
  - Review all 150+ endpoints
  - Add permission checks
  - No unprotected routes

- **T4.22** Permission bypass tests
  - Try to access as lower-privilege user
  - Verify 403 Forbidden
  - Test scope enforcement

- **T4.23** Privilege escalation tests
  - Try to assign Super Admin to self
  - Try to modify other tenant's data
  - Verify all blocked

- **T4.24** Audit log verification
  - All write operations logged
  - No PII in logs (GDPR)
  - Retention: 1 year

- **T4.25** Performance test
  - Permission check latency < 10ms
  - Cached permissions hit 95%
  - 1000 users, 50 roles

**T4.26-T4.30: Documentation & Rollout**
- **T4.26** RBAC documentation
  - Role descriptions
  - Permission list
  - How to create custom roles

- **T4.27** Admin guide
  - How to assign roles
  - Best practices
  - Security recommendations

- **T4.28** Migration guide
  - For existing customers
  - Map old admin → new roles
  - What changes for users

- **T4.29** Deploy RBAC
  - Run migrations
  - Assign roles to existing users
  - Monitor errors

- **T4.30** Train customer admins
  - Video tutorial
  - Live webinar
  - Support documentation

**✓ Done When:**
- All API endpoints protected
- Frontend hides/shows based on permissions
- Audit logs working
- 0 privilege escalation bugs
- 5 tenants using RBAC in production

---

### Phase 5: White-Label API for Resellers

**Why:** Enable resellers to sell under their brand (new revenue channel)  
**Timeline:** Week 13-16 (4 weeks)

#### Use Cases
1. **Reseller A** (GPS device vendor)
   - Buys 10,000 device slots from Bellerox
   - Sells GPS devices + tracking to end customers
   - Customers see Reseller A branding, not Bellerox
   - Reseller A pays Bellerox ฿25/vehicle, charges ฿40 (฿15 margin)

2. **Reseller B** (Software partner)
   - Integrates GPS into their logistics platform
   - API-only integration (no UI)
   - White-label API domain: `api.logisticsB.com` → proxies to Bellerox

3. **Reseller C** (Enterprise customer)
   - Needs custom domain for corporate security
   - Full white-label: logo, domain, SSL cert
   - Data still hosted by Bellerox, but invisible

#### Architecture
```
Reseller A Domain: gps.resellerA.com
    ├─ Frontend: Reseller A logo, colors
    ├─ API: api.resellerA.com → Bellerox API
    ├─ Billing: Reseller A collects payment
    └─ Support: Reseller A handles support

Bellerox Backend (invisible to end customer)
    ├─ Multi-tenant DB (tenant = resellerA)
    ├─ API Gateway (validates API key)
    └─ Billing: tracks usage, invoices reseller monthly
```

#### Features
- Custom domain (CNAME to Bellerox)
- Custom logo, colors, favicon
- White-label mobile app (Expo OTA update)
- API key authentication (not shared login)
- Separate billing per reseller
- Usage metering (API calls, vehicles, storage)
- Webhook notifications (events, alerts)

#### Tasks (28 tasks)

**T5.1-T5.5: Custom Domain Support**
- **T5.1** Multi-domain routing
  - Nginx virtual hosts
  - `gps.resellerA.com` → tenant A
  - `gps.resellerB.com` → tenant B

- **T5.2** SSL cert automation (per domain)
  - Certbot wildcard cert for `*.bellerox.com`
  - Bring-your-own-cert for custom domains
  - Auto-renewal per domain

- **T5.3** DNS CNAME validation
  - Reseller adds: `gps.resellerA.com CNAME gps.bellerox.com`
  - Backend verifies CNAME before activation
  - Show DNS check status in UI

- **T5.4** Domain mapping DB table
```sql
CREATE TABLE custom_domains (
  id SERIAL PRIMARY KEY,
  tenant_id INT REFERENCES tenants(id),
  domain VARCHAR(255) UNIQUE NOT NULL,
  ssl_cert_path VARCHAR(500),
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

- **T5.5** Domain verification flow
  - Admin enters domain in settings
  - Backend generates verification token
  - Admin adds TXT record: `_bellerox-verify=<token>`
  - Backend checks TXT record → marks verified

**T5.6-T5.10: White-Label Branding**
- **T5.6** Branding config API
  - PUT /api/tenants/:id/branding
  - Fields: logo, favicon, primaryColor, secondaryColor, companyName

- **T5.7** Logo upload
  - Accept PNG/SVG, max 2MB
  - Store in GCS bucket
  - CDN URL for fast loading

- **T5.8** Frontend theme injection
  - Load branding config on app init
  - Apply colors to CSS variables
  - Swap logo in header

- **T5.9** Email white-labeling
  - Alerts sent from `noreply@resellerA.com` (SMTP)
  - Email template uses reseller logo
  - Footer: "Powered by <reseller name>"

- **T5.10** Mobile app white-label
  - Expo OTA update per tenant
  - Dynamic app icon, splash screen
  - App Store: separate app per reseller (optional)

**T5.11-T5.15: API Key Authentication**
- **T5.11** API key generation
  - POST /api/tenants/:id/api-keys
  - Returns: `bellerox_live_abc123...` (48 chars)
  - Store hashed (bcrypt)

- **T5.12** API key scopes
  - `vehicles:read`, `positions:read`, `reports:read`
  - `webhooks:write` (for integrations)
  - No admin actions (users, billing)

- **T5.13** API key middleware
  - Header: `Authorization: Bearer bellerox_live_abc123`
  - Verify hash, load tenant context
  - Rate limit: 1000 req/min per key

- **T5.14** API key management UI
  - List keys, create, revoke
  - Show last used timestamp
  - Copy to clipboard

- **T5.15** API key rotation
  - Generate new key, deprecate old
  - 30-day grace period
  - Email notification before expiry

**T5.16-T5.20: Usage Metering & Billing**
- **T5.16** Usage tracking
  - Count: vehicles, API calls, storage (GB), alerts sent
  - Store in `usage_metrics` table (hourly aggregates)

- **T5.17** Billing tiers
  - Tier 1: 0-1,000 vehicles = ฿25/vehicle
  - Tier 2: 1,001-10,000 = ฿23/vehicle
  - Tier 3: 10,000+ = ฿20/vehicle
  - API calls: free up to 1M/month, then ฿0.01/1000 calls

- **T5.18** Invoice generation
  - Monthly invoice per tenant
  - PDF format
  - Email to billing contact

- **T5.19** Payment integration
  - Stripe for credit card
  - Thai QR Code (PromptPay) for local
  - Auto-retry failed payments

- **T5.20** Usage dashboard (reseller)
  - Graph: vehicles over time
  - Graph: API calls per day
  - Projected cost for current month

**T5.21-T5.25: Webhooks**
- **T5.21** Webhook endpoints table
```sql
CREATE TABLE webhook_endpoints (
  id SERIAL PRIMARY KEY,
  tenant_id INT REFERENCES tenants(id),
  url VARCHAR(500) NOT NULL,
  events TEXT[], -- ['vehicle.geofence.enter', 'alert.overspeed']
  secret VARCHAR(64), -- for HMAC signature
  enabled BOOLEAN DEFAULT true
);
```

- **T5.22** Webhook events
  - `vehicle.position.update` (every 60s, batched)
  - `vehicle.geofence.enter`, `vehicle.geofence.exit`
  - `alert.overspeed`, `alert.idling`
  - `device.online`, `device.offline`

- **T5.23** Webhook delivery
  - Queue in Redis
  - Worker sends POST to reseller URL
  - Retry: 3 attempts with exp backoff

- **T5.24** Webhook signature
  - HMAC-SHA256 with secret
  - Header: `X-Bellerox-Signature`
  - Reseller verifies signature

- **T5.25** Webhook logs UI
  - List deliveries (success/fail)
  - Retry failed webhooks
  - Disable endpoint if 100 consecutive fails

**T5.26-T5.28: Testing & Launch**
- **T5.26** Reseller onboarding flow
  - Sign up form
  - Domain setup wizard
  - Branding upload
  - API key generation

- **T5.27** Test with beta reseller
  - Onboard 1 reseller
  - 100 vehicles under their brand
  - Verify white-label works end-to-end

- **T5.28** Documentation
  - API reference (Swagger)
  - Webhook guide
  - Integration examples (Python, Node.js, PHP)

**✓ Done When:**
- 3 resellers running in production
- Each has custom domain + branding
- API integration working
- Billing automated

---

## 📊 PART 4: ADVANCED FEATURES (Month 5-6)

### Phase 6: Advanced Analytics & Reporting

**Timeline:** Month 5 (4 weeks)

#### Features
- Driver behavior scoring (harsh braking, acceleration, speeding)
- Fuel consumption tracking + prediction
- Route optimization suggestions
- Predictive maintenance (engine hours, mileage)
- Carbon footprint reporting (CO2 emissions)
- Custom reports builder (drag-drop UI)

#### Tasks (20 tasks)
- T6.1-T6.5: Driver scoring algorithm
- T6.6-T6.10: Fuel tracking + ML prediction
- T6.11-T6.15: Route optimization engine
- T6.16-T6.20: Custom report builder UI

### Phase 7: Mobile App Enhancements

**Timeline:** Month 5-6 (8 weeks)

#### Features
- Offline mode (cache positions, sync later)
- Push notifications (LINE + Firebase)
- Driver trip logging (start/end shift)
- Photo capture (delivery proof)
- Signature capture (recipient sign-off)
- Voice commands (Thai language)

#### Tasks (25 tasks)
- T7.1-T7.5: Offline sync with IndexedDB
- T7.6-T7.10: Push notifications
- T7.11-T7.15: Driver trip features
- T7.16-T7.20: Media capture (photo, signature)
- T7.21-T7.25: Voice commands (Google Speech API)

### Phase 8: Compliance & Certifications

**Timeline:** Month 6 (4 weeks)

#### Certifications Needed for Enterprise
- **SOC 2 Type II** — security audit (required by Fortune 500)
- **ISO 27001** — information security management
- **GDPR compliance** — if selling in EU
- **Thai PDPA compliance** — already in place, formal audit
- **PCI DSS** (if storing payment cards)

#### Tasks (15 tasks)
- T8.1-T8.5: SOC 2 preparation + audit
- T8.6-T8.10: ISO 27001 documentation
- T8.11-T8.15: GDPR/PDPA formal audit

---

## 🚀 PART 5: DEPLOYMENT & OPERATIONS

### Phase 9: CI/CD Pipeline Hardening

**Timeline:** Week 3-4 (parallel with cost optimization)

#### Current Pipeline Issues
- Manual deploy to GCP VM
- No staging environment
- No automated tests in CI
- No rollback mechanism

#### Target Pipeline
```
GitHub Push → GitHub Actions
    ├─ Lint + TypeScript check
    ├─ Unit tests (Jest)
    ├─ Integration tests (Supertest)
    ├─ Build Docker images
    ├─ Push to GCR (Google Container Registry)
    ├─ Deploy to Staging (GKE)
    ├─ E2E tests (Playwright)
    ├─ Deploy to Production (blue-green)
    └─ Smoke tests + Rollback if fail
```

#### Tasks (18 tasks)
- T9.1-T9.5: Staging environment setup
- T9.6-T9.10: Automated testing suite
- T9.11-T9.15: Blue-green deployment
- T9.16-T9.18: Rollback automation

### Phase 10: Monitoring & Observability

**Timeline:** Week 4 (parallel with CI/CD)

#### Stack
- **Metrics:** Prometheus + Grafana (already running)
- **Logs:** Loki (centralized logging)
- **Traces:** Jaeger (distributed tracing)
- **Alerts:** PagerDuty (on-call rotation)
- **Uptime:** StatusPage (public status)

#### Dashboards
1. **Infrastructure:** CPU, memory, disk, network
2. **Application:** API latency, error rate, throughput
3. **Business:** Active vehicles, API calls, revenue
4. **Security:** Failed logins, 403s, rate limit hits

#### Tasks (15 tasks)
- T10.1-T10.5: Loki + Grafana logging
- T10.6-T10.10: Jaeger tracing
- T10.11-T10.15: PagerDuty alerts + StatusPage

---

## 📈 SUCCESS METRICS

| Metric | Current | Target | Timeline |
|--------|---------|--------|----------|
| **Vehicles under management** | 4,000 | 20,000 | Month 6 |
| **Enterprise customers** | 0 | 10 | Month 6 |
| **Resellers** | 0 | 5 | Month 6 |
| **API uptime** | 99.5% | 99.9% | Month 3 |
| **Page load time** | 2-3s | < 1s | Month 2 |
| **Infrastructure cost** | $934/mo | $560/mo | Month 1 |
| **Support tickets** | 50/mo | 20/mo | Month 4 |
| **Security incidents** | 1/quarter | 0 | Month 3 |

---

## 💰 COST ESTIMATE

| Phase | Labor (weeks) | Cost @ ฿50k/week | Infrastructure | Total |
|-------|---------------|------------------|----------------|-------|
| Phase 0: Rollback Recovery | 0.25 | ฿12,500 | ฿0 | ฿12,500 |
| Phase 1: HTTPS/SSL | 2 | ฿100,000 | ฿5,000 | ฿105,000 |
| Phase 2: Cost Optimization | 2 | ฿100,000 | -฿374,000/mo | ฿100,000 |
| Phase 3: Multi-Tenant | 4 | ฿200,000 | ฿20,000 | ฿220,000 |
| Phase 4: RBAC | 4 | ฿200,000 | ฿10,000 | ฿210,000 |
| Phase 5: White-Label | 4 | ฿200,000 | ฿15,000 | ฿215,000 |
| Phase 6: Analytics | 4 | ฿200,000 | ฿30,000 | ฿230,000 |
| Phase 7: Mobile | 8 | ฿400,000 | ฿10,000 | ฿410,000 |
| Phase 8: Compliance | 4 | ฿200,000 | ฿200,000 | ฿400,000 |
| Phase 9: CI/CD | 2 | ฿100,000 | ฿15,000 | ฿115,000 |
| Phase 10: Monitoring | 2 | ฿100,000 | ฿25,000 | ฿125,000 |
| **TOTAL** | **36 weeks** | **฿1,812,500** | **฿330,000** | **฿2,142,500** |

**ROI Calculation:**
- Cost optimization saves ฿374,000/month
- Pays for itself in **6 months**
- Year 1 net savings: ฿2,346,000

---

## 🎯 PRIORITIZATION RATIONALE

### P0 (Week 1) — Rollback Recovery
**Why first:** Production broken (429 errors), blocks DLT reporting

### P0 (Week 2-3) — HTTPS/SSL
**Why next:** Security requirement for enterprise sales

### P1 (Week 3-4) — Cost Optimization
**Why parallel:** Pays for itself, can run alongside HTTPS work

### P1 (Week 5-8) — Multi-Tenant
**Why before RBAC:** Foundation for enterprise architecture

### P2 (Week 9-12) — RBAC
**Why after multi-tenant:** Depends on tenant infrastructure

### P2 (Week 13-16) — White-Label
**Why after RBAC:** Resellers need role-based permissions

### P3 (Month 5-6) — Advanced Features
**Why last:** Nice-to-have, not blockers for enterprise

---

## 📚 APPENDICES

### Appendix A: Technology Choices

| Decision | Technology | Why | Alternatives Rejected |
|----------|-----------|-----|----------------------|
| Multi-tenant DB | Single Postgres + RLS | Cost-effective, simpler ops | Separate DB per tenant (too expensive) |
| RBAC | Custom implementation | Flexible, Traccar-compatible | Keycloak (too heavy), Auth0 (expensive) |
| White-label | CNAME + branding config | Simple, scalable | Separate instances (too expensive) |
| SSL | Let's Encrypt + Certbot | Free, automated | Paid cert (unnecessary cost) |
| Monitoring | Prometheus + Grafana | Already deployed | DataDog (expensive) |

### Appendix B: Migration Checklist

**Before rollout:**
- [ ] Backup production database
- [ ] Test migrations on staging (copy of production)
- [ ] Write rollback scripts for every migration
- [ ] Schedule maintenance window (low traffic time)
- [ ] Notify customers 7 days in advance

**During rollout:**
- [ ] Enable maintenance mode
- [ ] Run migrations
- [ ] Verify data integrity
- [ ] Deploy new code
- [ ] Smoke tests
- [ ] Disable maintenance mode
- [ ] Monitor errors for 2 hours

**Rollback triggers:**
- Error rate > 5%
- Query latency > 2x baseline
- Any data corruption detected
- Customer reports > 10 in 1 hour

### Appendix C: Support Plan

**During implementation:**
- Daily standup (15 min)
- Weekly progress review (1 hour)
- Slack channel for quick questions
- Shared Google Doc for decisions

**Post-launch:**
- 24/7 on-call rotation (PagerDuty)
- Monthly health check meeting
- Quarterly roadmap review
- Annual security audit

---

**End of Master Plan**

**Total:** 10 Phases, 50+ sub-phases, 300+ tasks, 36 weeks  
**Next Step:** Review + approve Phase 0 (Rollback Recovery) to start immediately