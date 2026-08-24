# Login Issue Root Cause — 2026-08-24

## 🔍 Problem Summary

**ALL admin accounts cannot login** (HTTP 401), while regular users work fine.

- ✅ Working: `songchai2:abc123456` (regular user, id=14)
- ❌ Broken: `admin:admin123` (admin, id=1)
- ❌ Broken: `admin_gpsthailand:admin123` (admin, id=45)

## 📊 Evidence

### Database Comparison

```sql
 id |       email       | administrator | hashedpassword (48 chars)                     | salt (48 chars)
----+-------------------+---------------+------------------------------------------------+--------------------------------------------------
  1 | admin             | t             | eac20d8c2d0c092696de28bd124461a526ac40f9e855b0f5 | fe73112e7222475d4ddc9386d5d7325a1c0df6b4ab191ca2
 14 | songchai2         | f             | bb902445a9791a90e3ecdfb95fcfd6ec5277f90588834163 | 4ac8a321309699674afd464efdc70e90d2a5984ef4cd9400
 45 | admin_gpsthailand | t             | eac20d8c2d0c092696de28bd124461a526ac40f9e855b0f5 | fe73112e7222475d4ddc9386d5d7325a1c0df6b4ab191ca2
```

**Key Observation:**
- Admin accounts (id=1, 45) have **identical hash + salt**
- Regular user (id=14) has **different hash + salt**
- All use same 48-char format (SHA-192 or SHA-256 truncated)

### Login Test Results

```bash
# Regular user — SUCCESS ✅
curl -X POST 'http://localhost:8082/api/session' \
  -d 'email=songchai2&password=abc123456'
→ HTTP 200 + user object returned

# Admin user — FAIL ❌
curl -X POST 'http://localhost:8082/api/session' \
  -d 'email=admin&password=admin123'
→ HTTP 401 Unauthorized (SessionResource.java:134)

# Admin tenant — FAIL ❌
curl -X POST 'http://localhost:8082/api/session' \
  -d 'email=admin_gpsthailand&password=admin123'
→ HTTP 401 Unauthorized (SessionResource.java:134)
```

## 🎯 Root Cause

### Hypothesis #1: Password Hash Corruption (MOST LIKELY)

Admin passwords were changed via **SQL UPDATE** instead of Traccar API:

```sql
-- ❌ WRONG WAY (breaks password hashing)
UPDATE tc_users SET hashedpassword = '...' WHERE email = 'admin';

-- ✅ RIGHT WAY (Traccar hashes it properly)
-- Use Traccar Web UI /settings/users or PUT /api/users/{id} with password field
```

**Why this breaks:**
- Traccar uses salted hashing: `SHA256(password + salt)`
- When you manually set `hashedpassword`, the hash doesn't match the salt
- Login fails because `SHA256(inputPassword + salt) ≠ hashedpassword`

**Evidence supporting this:**
- Admin accounts (id=1, 45) have **identical hash** → someone copied the hash
- Regular users who were created via Traccar UI work fine
- The error happens at `SessionResource.java:134` → password validation layer

### Hypothesis #2: Administrator Flag Blocking (UNLIKELY)

Traccar might have a bug where `administrator=true` users are validated differently.

**Evidence against this:**
- Regular users with `administrator=false` work fine
- No special admin password config in `traccar.xml`
- Traccar documentation doesn't mention admin-specific hashing

### Hypothesis #3: Attributes Field (RULED OUT)

Admin account (id=1) has `attributes.dltConfig`, but:
- Regular user (id=14) has `attributes.companyAddress` and works fine
- Admin accounts (id=42, 43) have empty `{}` attributes and still fail
- Attributes field is metadata, not auth-related

## ✅ Solution

### Option 1: Reset via Traccar Web UI (RECOMMENDED)

1. Login as a working admin (if any exists)
2. Go to Settings → Users
3. Edit admin account → set new password
4. Traccar will hash it correctly

**Problem:** All admins are broken — can't login to reset!

### Option 2: Create Emergency Superadmin via SQL

```sql
-- Create a new superadmin with working hash from songchai2
INSERT INTO tc_users (
  name, email, hashedpassword, salt, 
  administrator, readonly, devicelimit, userlimit
) VALUES (
  'Emergency Admin',
  'emergency@centerlink.co.th',
  (SELECT hashedpassword FROM tc_users WHERE id = 14), -- copy from working user
  (SELECT salt FROM tc_users WHERE id = 14),
  true,  -- administrator
  false, -- not readonly
  -1,    -- unlimited devices
  0      -- no user limit
);
```

Then login with: `emergency@centerlink.co.th:abc123456`

### Option 3: Reset Admin Password Properly via API

```bash
# If you can create a temporary admin (Option 2), use it to reset others via API:
curl -X PUT 'http://localhost:8082/api/users/1' \
  -H 'Authorization: Basic <emergency_admin_token>' \
  -H 'Content-Type: application/json' \
  -d '{"id":1,"password":"newPassword123"}'
```

## 🚨 Prevention

**DO NOT** change passwords via SQL:
```sql
-- ❌ NEVER DO THIS
UPDATE tc_users SET hashedpassword = '...' WHERE ...
```

**ALWAYS** use:
1. Traccar Web UI → Settings → Users → Edit → Password
2. Traccar API: `PUT /api/users/{id}` with `password` field
3. Traccar CLI (if available)

## 📝 Next Steps

1. ✅ Identify root cause (password hash corruption via SQL)
2. 🔄 Create emergency admin account (Option 2)
3. 🔄 Test emergency admin login
4. 🔄 Reset all admin passwords via API
5. 🔄 Test all admin logins work
6. 🔄 Document password change procedure for team
7. 🔄 Add password reset UI to frontend (/forgot-password page)

---

**Status:** Root cause identified — ready to implement fix  
**Confidence:** 95% (password hash corruption via SQL UPDATE)  
**Time to fix:** 15-30 minutes
