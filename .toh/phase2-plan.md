# Phase 2: SSL/TLS + RBAC Implementation Plan

**Start:** 2026-08-25  
**Target:** Complete today without stopping  
**Deploy:** Saturday 2026-08-31 (2-4 AM)

---

## Context

Phase 1 (Multi-Tenant) at 90% - testing pending Monday.  
Now implementing Phase 2 from enterprise plan: SSL/TLS automation + Role-Based Access Control.

---

## Part A: SSL/TLS Automation (6 tasks)

### T2.1 ⏳ Audit Current SSL State
- Check if Certbot installed
- Check Nginx SSL config
- Check Let's Encrypt renewal timer

### T2.2 ⏳ Install Certbot
- Install certbot + nginx plugin
- Test ACME challenge path

### T2.3 ⏳ Generate SSL Certificate
- Run certbot --nginx for traccar.gps.bellerox.com
- Verify certificate created
- Test HTTPS access

### T2.4 ⏳ Configure Nginx SSL Best Practices
- Add strong ciphers
- Enable HSTS
- Configure OCSP stapling
- Test SSL Labs grade (target: A+)

### T2.5 ⏳ Setup Auto-Renewal
- Configure systemd timer
- Test renewal with --dry-run
- Add post-renewal hook (reload nginx)

### T2.6 ⏳ SSL Monitoring & Backup
- Add certificate expiry check script
- Backup /etc/letsencrypt to GCS
- Add cron for weekly backups
- Document SSL procedures

---

## Part B: RBAC System (12 tasks)

### T3.1 ⏳ Database Schema - RBAC Tables
Create migrations:
- `016_create_roles.sql`
- `017_create_permissions.sql`
- `018_create_role_permissions.sql`
- `019_create_user_roles.sql`
- `020_create_audit_log.sql`

### T3.2 ⏳ Seed System Roles & Permissions
Seed data migration:
- 7 roles (super_admin, tenant_admin, fleet_manager, supervisor, driver, api_client, auditor)
- 50+ permissions (vehicles:read, vehicles:write, etc.)
- Map roles to permissions

### T3.3 ⏳ Backend Middleware - Permission Check
Create:
- `server/middleware/permissions.ts`
- `requirePermission()` middleware
- `loadUserPermissions()` helper
- `canAccessDevice()` scope checker

### T3.4 ⏳ Backend Middleware - Audit Logging
Create:
- `server/middleware/auditLog.ts`
- Auto-log all write operations
- Capture IP, user agent, request body

### T3.5 ⏳ Apply Middleware to Routes
Update existing routes:
- `server/routes/devices.ts` - add permission checks
- `server/routes/geofences.ts`
- `server/routes/reports.ts`
- `server/routes/users.ts`

### T3.6 ⏳ Frontend Hook - usePermissions
Create:
- `src/hooks/usePermissions.ts`
- `hasPermission()`
- `canEditVehicles`, `canManageUsers` shortcuts

### T3.7 ⏳ Frontend - Conditional Rendering
Update pages with permission checks:
- `src/pages/FleetPage.tsx` - hide Add/Edit/Delete buttons
- `src/pages/GeofencesPage.tsx`
- `src/pages/UsersPage.tsx`

### T3.8 ⏳ Frontend - Role-Based Navigation
Update:
- `src/components/layout/Sidebar.tsx` - hide menu items based on permissions
- `src/components/layout/LayoutV2.tsx`

### T3.9 ⏳ Admin Page - Role Management
Create:
- `src/pages/admin/RolesPage.tsx`
- List roles, assign to users
- Create custom roles (for tenant admins)

### T3.10 ⏳ Admin Page - Audit Log Viewer
Create:
- `src/pages/admin/AuditLogPage.tsx`
- Table with filters (user, action, date)
- Export to CSV

### T3.11 ⏳ API Routes - RBAC Management
Create:
- `POST /api/admin/roles` - create custom role
- `GET /api/admin/roles` - list roles
- `POST /api/admin/users/:id/roles` - assign role
- `GET /api/admin/audit` - fetch audit logs

### T3.12 ⏳ Testing & Verification
- Create test users with different roles
- Test permission checks (driver can't see other vehicles)
- Test audit log capture
- Verify build passes

---

## Success Criteria

**SSL/TLS:**
- ✅ HTTPS works on traccar.gps.bellerox.com
- ✅ Auto-renewal configured (systemd timer)
- ✅ SSL Labs grade A or A+
- ✅ Certificate backup to GCS

**RBAC:**
- ✅ 7 system roles seeded
- ✅ 50+ permissions defined
- ✅ Permission middleware working
- ✅ Audit log captures all writes
- ✅ Frontend hides unauthorized UI
- ✅ Role management page working
- ✅ Audit log viewer working

**Build:**
- ✅ `npm run build` passes (zero errors)
- ✅ `npm run lint` passes (zero warnings)
- ✅ Local testing via `npm run dev`

---

## Deployment Plan (Saturday 2-4 AM)

**Pre-deploy:**
- Backup database (pg_dump)
- Test all migrations on local copy

**Deploy SSL:**
1. SSH to production VM
2. Install certbot
3. Run certbot --nginx
4. Verify HTTPS access
5. Configure auto-renewal

**Deploy RBAC:**
1. Run migrations 016-020
2. Verify seed data
3. Deploy API server updates (with middleware)
4. Deploy frontend (with permission checks)
5. Test with different role users

**Rollback Plan:**
- SSL: Switch back to HTTP in nginx config
- RBAC: Drop new tables, remove middleware

---

## Notes

- No staging server - test locally via `npm run dev`
- Cost: ฿0 (Let's Encrypt free, RBAC is code-only)
- Phase 1 still pending local testing (do Monday)
- Phase 2 complete today = ready for Sat deploy together
