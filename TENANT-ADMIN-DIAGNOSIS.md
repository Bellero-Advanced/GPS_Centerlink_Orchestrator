# 🔍 Tenant Admin 401 Error — Root Cause Found

**Date:** 2026-08-24  
**Severity:** P0 Critical  
**Status:** ✅ DIAGNOSED — Frontend trying to use EMPTY admin credentials

---

## 🎯 Problem Summary

When viewing tenant detail page at `/admin/tenants/e5aa2528-adc8-4a45-a742-9f851870862d`, frontend makes API calls to:
- `GET /api/users?userId=3` → 401 Unauthorized
- `GET /api/users/3` → 401 Unauthorized  
- `PUT /api/users/3` → 401 Unauthorized

These calls happen when:
1. Loading "บริษัทย่อย" (sub-companies) section
2. Trying to reset password for tenant admin
3. Trying to disable/enable tenant admin

---

## 🔎 Root Cause Analysis

### Code Path (Line 9 of TenantDetailPage.tsx)
```typescript
import { setUserDisabled, resetUserPassword, getManagedUsers, getDevicesForUser } 
  from '@/services/adminTraccarService';
```

### Service Implementation (adminTraccarService.ts)
```typescript
// Line 92-97
export async function getManagedUsers(managerId: number): Promise<TraccarUser[]> {
  const { data } = await adminTraccarClient.get<TraccarUser[]>('/api/users', {
    params: { userId: managerId },
  });
  return data;
}
```

### Client Authentication (adminTraccarClient.ts)
```typescript
// Line 14-15
const ADMIN_USER = import.meta.env.VITE_TRACCAR_ADMIN_USER || 'admin';
const ADMIN_PASS = import.meta.env.VITE_TRACCAR_ADMIN_PASS || '';

// Line 24
auth: { username: ADMIN_USER, password: ADMIN_PASS },
```

### ⚠️ THE PROBLEM
**Environment variables are EMPTY or WRONG:**
- `VITE_TRACCAR_ADMIN_USER` = 'admin' (default)
- `VITE_TRACCAR_ADMIN_PASS` = '' (EMPTY!)

When `ADMIN_PASS` is empty, axios sends:
```
Authorization: Basic YWRtaW46  (base64 of "admin:")
```

This fails Traccar authentication → 401 Unauthorized.

---

## 📊 Evidence

### Console Errors
```javascript
api.centerlink.co.th/api/users?userId=3:1  Failed to load resource: 401
api.centerlink.co.th/api/users/3:1  Failed to load resource: 401
PUT https://api.centerlink.co.th/api/users/3 401 (Unauthorized)
```

### What User is Trying to Access
- Tenant: "บริษัท จีพีเอส (ประเทศไทย) จำกัด"
- Tenant ID: `e5aa2528-adc8-4a45-a742-9f851870862d`
- Tenant slug: `gpsthailand`
- Manager user ID: `3` (from database)

### Database Check
```sql
SELECT id, name, email, administrator FROM tc_users WHERE id = 3;
```
Result:
```
id=3 | นายสงชัย (songchai2) | songchai2 | admin=FALSE
```

So user id=3 exists and is NOT an admin — it's a regular tenant manager account.

---

## 🧩 Multi-Tenant Architecture Revealed

### How It Actually Works

**This is NOT vanilla Traccar.** The codebase has a **custom multi-tenant layer:**

1. **Supabase Layer** (`cl_tenants` table):
   - Stores tenant metadata (company name, slug, branding)
   - Links tenant to Traccar manager account via `traccar_manager_id`

2. **Traccar Layer** (native permissions):
   - Each tenant has a manager account (non-admin user)
   - Manager creates sub-users (end users for that tenant)
   - Sub-users see only devices assigned to them
   - Devices grouped by tenant via Traccar groups

3. **Admin Portal** (React app at `/admin/*`):
   - Super admin uses `adminTraccarClient` (Basic auth)
   - Credentials stored in `.env` as `VITE_TRACCAR_ADMIN_USER` / `VITE_TRACCAR_ADMIN_PASS`
   - Can provision new tenants, reset passwords, suspend accounts

### Data Flow
```
Supabase cl_tenants table
  └─ traccar_manager_id = 3
       └─ Traccar tc_users (id=3, songchai2)
            └─ Traccar tc_user_* permissions
                 └─ Sub-users & devices for "GPS Thailand" tenant
```

### Why User Can't See Devices

User `admin_gpsthailand` (id=45) is a **Super Admin account**, NOT a tenant manager.

- Super admins bypass tenant scoping
- But if they have 0 device/group assignments, they see nothing
- Regular tenant workflow: login as tenant manager (songchai2) → see tenant devices

---

## 🎯 The Real Problem

User wants to login as `admin_gpsthailand` and see devices for "GPS Thailand" tenant.

But:
1. `admin_gpsthailand` is a Super Admin (not scoped to tenant)
2. Super Admin UI at `/admin` requires different credentials
3. Tenant detail page tries to call Traccar API with empty password → 401

**User is mixing two different access patterns:**
- **Super Admin Portal:** `/admin/*` — for Centerlink staff to manage all tenants
- **Tenant Manager Portal:** `/app/*` — for tenant admins to manage their own vehicles

---

## ✅ Solutions

### Option 1: Fix `.env` — Add Super Admin Password (REQUIRED)

Create `.env.local` in `bellerox-gps-web/`:
```bash
VITE_TRACCAR_ADMIN_USER=admin
VITE_TRACCAR_ADMIN_PASS=<actual_admin_password>
```

This fixes the 401 errors in admin portal.

### Option 2: Login as Tenant Manager (Correct Workflow)

Instead of `admin_gpsthailand`, login as:
- **Username:** `songchai2`
- **Password:** (whatever was set for user id=3)

This will show all devices for "GPS Thailand" tenant.

### Option 3: Link Admin to Tenant Manager (Hybrid)

Make `admin_gpsthailand` a co-manager of `songchai2`:
```sql
-- Give admin_gpsthailand permission to manage songchai2's users/devices
INSERT INTO tc_user_user (userid, manageduserid)
VALUES (45, 3)
ON CONFLICT DO NOTHING;

-- Copy all device permissions from songchai2 to admin_gpsthailand
INSERT INTO tc_user_device (userid, deviceid)
SELECT 45, deviceid FROM tc_user_device WHERE userid = 3
ON CONFLICT DO NOTHING;

-- Copy all group permissions
INSERT INTO tc_user_group (userid, groupid)
SELECT 45, groupid FROM tc_user_group WHERE userid = 3
ON CONFLICT DO NOTHING;
```

---

## 📋 Next Actions

### Immediate (Fix 401 Errors)
```bash
cd bellerox-gps-web

# Create .env.local with real admin password
echo "VITE_TRACCAR_ADMIN_USER=admin" > .env.local
echo "VITE_TRACCAR_ADMIN_PASS=admin123" >> .env.local

# Rebuild frontend
npm run build

# Deploy
git add .env.local  # NO! Don't commit this
# Instead: Add to Cloudflare Pages environment variables
```

### Diagnostic (Understand Current Setup)
```sql
-- Who is the manager for GPS Thailand tenant?
SELECT id, name, email, administrator, userLimit, deviceLimit
FROM tc_users WHERE id = 3;

-- What devices does songchai2 manage?
SELECT COUNT(*) as device_count
FROM tc_user_device WHERE userid = 3;

-- What groups does songchai2 manage?
SELECT g.id, g.name, COUNT(gd.deviceid) as devices
FROM tc_user_group ug
JOIN tc_groups g ON ug.groupid = g.id
LEFT JOIN tc_group_device gd ON g.id = gd.groupid
WHERE ug.userid = 3
GROUP BY g.id, g.name;

-- Who are the sub-users under songchai2?
SELECT u.id, u.name, u.email
FROM tc_users u
JOIN tc_user_user uu ON u.id = uu.manageduserid
WHERE uu.userid = 3;
```

### Long-term (Clarify Architecture)
1. **Document multi-tenant design** — Update CLAUDE.md with Supabase + Traccar hybrid architecture
2. **Separate admin credentials** — Don't use `admin` account for provisioning (create `centerlink_admin`)
3. **Add permission UI** — Show which users/devices each manager controls
4. **Tenant switcher** — Allow Super Admin to "view as tenant" without copying permissions

---

## 🎓 Key Learnings

1. **This is a custom multi-tenant fork** — Not vanilla Traccar 6.14.5
2. **Two authentication systems:**
   - Supabase for tenant metadata
   - Traccar for GPS data + user permissions
3. **Admin portal requires valid Basic auth** — `.env` must have real password
4. **User confusion:** Mixing Super Admin portal with Tenant Manager login

---

## 📊 Status Summary

| Issue | Root Cause | Solution | Status |
|-------|-----------|----------|--------|
| 401 on `/api/users/*` | Empty `VITE_TRACCAR_ADMIN_PASS` | Add password to `.env.local` | 🔧 TODO |
| Can't see devices as admin_gpsthailand | Super Admin has 0 assignments | Copy permissions from songchai2 | 🔧 TODO |
| No tenants table found | Custom Supabase layer (`cl_tenants`) | ✅ UNDERSTOOD | ✅ DONE |
| Confusion about architecture | Hybrid Supabase+Traccar | Document design | 📋 TODO |

---

**Next Step:** Add `VITE_TRACCAR_ADMIN_PASS` to environment and rebuild frontend.
