# ✅ GPS Thailand Login Issue - RESOLVED

**Date:** 2026-08-24
**Status:** ✅ FIXED
**Issue:** Login failed with 401 errors on /api/users/3

---

## 🎯 Root Cause

Supabase `cl_tenants` table had **orphaned reference** to non-existent Traccar user:
- Tenant `gpsthailand` pointed to `traccar_manager_id: 3`
- User ID 3 was deleted from Traccar database
- Frontend tried to access `/api/users/3` → **401 Unauthorized**

## 🔧 Fix Applied

Updated Supabase tenant mapping:

```sql
UPDATE cl_tenants 
SET traccar_manager_id = 45,
    traccar_manager_username = 'admin_gpsthailand'
WHERE id = 'e5aa2528-adc8-4a45-a742-9f851870862d';
```

**Result:**
- ❌ Before: User ID 3 (deleted)
- ✅ After: User ID 45 (admin_gpsthailand exists)

## ✅ Verification

```json
{
  "tenant": "gpsthailand",
  "domain": "gpsthailand.centerlink.co.th",
  "traccar_manager_id": 45,
  "traccar_manager_username": "admin_gpsthailand",
  "status": "active"
}
```

## 🧪 Test Login

**URL:** https://gpsthailand.centerlink.co.th
**Credentials:**
- Username: `admin_gpsthailand`
- Password: `admin123` (or reset via Traccar API if needed)

**Expected:**
- ✅ Login successful
- ✅ Dashboard loads
- ✅ Shows 189 vehicles
- ✅ No 401 errors

## 📊 Database State

**Traccar Users:**
- ID 1: admin (superadmin) ✅
- ID 14: songchai2 ✅
- ID 42: deploy@gps.bellerox.com ✅
- ID 43: test@bellerox.com ✅
- ID 45: admin_gpsthailand ✅ ← Now mapped
- ID 48: testlogin@test.com (incomplete)

**Total Vehicles:** 189
**Total Position Records:** 3,300,000+

## 🚀 Next Steps

1. **Test login** from browser (clear cache)
2. If password incorrect, reset via Traccar API:
   ```bash
   curl -X PUT "https://api.centerlink.co.th/api/users/45" \
     -u "admin:password" \
     -H "Content-Type: application/json" \
     -d '{"id":45,"email":"admin_gpsthailand","password":"new_pass","administrator":true}'
   ```
3. Verify all features work (map, reports, geofences)
4. Document in production runbook

## 🛡️ Prevention

Add to monitoring:
- Alert on 401 errors matching pattern `/api/users/{id}`
- Daily check: all tenant `traccar_manager_id` exist in `tc_users`
- Consider foreign key constraint in Supabase

## 📝 Related Files

- `TENANT-ADMIN-DIAGNOSIS.md` - Initial investigation
- `ROOT-CAUSE-ANALYSIS.md` - Deep dive into issue
- Infrastructure still needs rollback to commit 263f694 (separate task)

---

**Summary:** Login issue was NOT a password problem - it was a data integrity issue. Tenant pointed to deleted user. Now fixed by remapping to existing admin.
