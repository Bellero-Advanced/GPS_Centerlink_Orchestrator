# 🔐 Login Authentication Fix Plan

**Status:** draft  
**Created:** 2026-08-24  
**Priority:** 🔴 CRITICAL (Production down)  
**Model:** claude-opus-5

---

## 🎯 Goal

แก้ปัญหา login ไม่ได้ทุก account (ทั้ง admin และ user ทั่วไป) ใน production

---

## 📊 Problem Statement

**อาการ:**
- ❌ ทุก user login ไม่ได้ (HTTP 401 Unauthorized)
- ❌ แม้ admin account หลัก (id=1, email=admin) ก็ login ไม่ได้
- ❌ ทดสอบด้วย curl ตรง server (localhost:8082) → 401
- ❌ ปัญหาอยู่ที่ Traccar authentication ไม่ใช่ frontend/nginx

**Evidence จาก Investigation:**
```sql
-- Admin users ที่มีอยู่:
id=1  | admin                   | SHA256 hash (64 chars) | same salt
id=42 | deploy@gps.bellerox.com | SHA256 hash (64 chars) | same salt  
id=43 | test@bellerox.com       | bcrypt hash (48 chars) | different salt ⚠️
id=45 | admin_gpsthailand       | SHA256 hash (64 chars) | same salt
```

**Root Cause Hypothesis:**
Traccar version อาจได้ upgrade และเปลี่ยนจาก SHA256+salt → bcrypt hashing
- ID 43 มี bcrypt hash (48 chars) — รูปแบบใหม่
- ID 1, 42, 45 มี SHA256 hash (64 chars) — รูปแบบเก่า (legacy)
- **Legacy SHA256 passwords ไม่ work กับ bcrypt validator**

---

## ✅ Done When

- [ ] เข้าใจ root cause ชัดเจน (bcrypt migration หรือ config ผิด)
- [ ] Admin account อย่างน้อย 1 account login ได้
- [ ] Frontend login form ทำงานปกติ
- [ ] มี documented process สำหรับ password migration
- [ ] Test coverage: curl + frontend login

---

## 📋 Phases

### Phase 1: Root Cause Verification

**Objective:** ยืนยัน root cause — bcrypt migration หรือ Traccar config issue

- [ ] **T101** `root-cause-debugger` — Check Traccar version จาก container
  - Command: `docker exec centerlink-traccar java -version`
  - Command: `docker exec centerlink-traccar cat /opt/traccar/version.txt`
  - Expected: Traccar 6.x (bcrypt era)

- [ ] **T102** `root-cause-debugger` — ตรวจสอบ password hashing config
  - File: `/opt/traccar/conf/traccar.xml`
  - Search: `password`, `hash`, `bcrypt`, `sha256`
  - Expected: พบ config ที่บ่งชี้ hash algorithm

- [ ] **T103** `root-cause-debugger` — ทดสอบ bcrypt user (id=43)
  - Login: test@bellerox.com (bcrypt hash)
  - Expected: login สำเร็จ = ยืนยันว่าเป็น bcrypt migration

**Checkpoint 1:** รู้ root cause แน่ชัด — bcrypt migration หรือ config corruption

---

### Phase 2: Emergency Admin Access

**Objective:** สร้าง admin account ใหม่ที่ login ได้ (bypass legacy hash)

- [ ] **T201** `backend-connector` — Create new superadmin via Traccar API
  - API: `POST /api/users` with proper bcrypt password
  - Credentials: superadmin / (new secure password)
  - Verify: Login test ผ่าน

- [ ] **T202** `backend-connector` — Fallback: SQL insert if API fails
  - Clone bcrypt hash จาก ID 43 (test@bellerox.com)
  - SQL: `INSERT INTO tc_users (name, email, hashedpassword, salt, administrator)`
  - Verify: Login test ผ่าน

**Checkpoint 2:** มี admin account 1 account ที่ login ได้แน่นอน

---

### Phase 3: Password Migration Strategy

**Objective:** Reset passwords ให้ใช้ bcrypt format ทั้งหมด

- [ ] **T301** `plan-orchestrator` — Document password reset procedure
  - File: `PASSWORD-MIGRATION-GUIDE.md`
  - Content: Steps สำหรับ reset via Traccar Web UI
  - Content: Bulk reset script for all users

- [ ] **T302** `backend-connector` — Reset all admin passwords
  - Via Traccar Web UI (superadmin account)
  - Users: admin (id=1), deploy (id=42), admin_gpsthailand (id=45)
  - New passwords: secure + documented

- [ ] **T303** `backend-connector` — Add "Forgot Password" link to LoginPage
  - Component: `LoginPage.tsx`
  - Link to: Traccar built-in `/api/password/reset`
  - Test: Email flow works

**Checkpoint 3:** ทุก admin login ได้ + users สามารถ reset เองได้

---

### Phase 4: Verification & Documentation

**Objective:** ยืนยันว่าระบบทำงานปกติและ document ไว้

- [ ] **T401** `test-runner` — Test all admin logins
  - curl test: admin, deploy, admin_gpsthailand, superadmin
  - Frontend test: login form → dashboard
  - Expected: ทุก account login สำเร็จ

- [ ] **T402** `test-runner` — Test regular user login
  - Pick 2-3 non-admin users
  - Test login via frontend
  - Expected: login สำเร็จ

- [ ] **T403** `plan-orchestrator` — Create incident report
  - File: `LOGIN-INCIDENT-2026-08-24.md`
  - Content: Timeline, root cause, fix applied, prevention
  - Save to: project root

**Checkpoint 4:** Login flow ทำงานปกติ + มี documentation ครบ

---

## 🎯 Alternative Solutions (if bcrypt not the cause)

### Alternative A: Database Corruption
- Export all users to CSV
- Recreate users via Traccar API (fresh bcrypt hashes)
- Re-assign devices and permissions

### Alternative B: Traccar Config Issue
- Check `traccar.xml` for password config
- Restart Traccar with default config
- Re-import users

### Alternative C: Session/Cookie Issue
- Clear all sessions: `DELETE FROM tc_sessions`
- Restart Traccar
- Test login

---

## 📊 Risk Assessment

**Risk:** HIGH  
- Production login down → ลูกค้าเข้าไม่ได้
- ต้องแก้ภายใน 1-2 ชม.

**Mitigation:**
- Phase 2 มี 2 ทางเลือก (API + SQL fallback)
- ไม่ลบ users เก่า (safe rollback)
- Test thoroughly ก่อน deploy

---

## ⏱️ Estimated Time

- Phase 1: 30 นาที (investigation)
- Phase 2: 30 นาที (emergency access)
- Phase 3: 1 ชม. (password migration)
- Phase 4: 30 นาที (verification)
- **Total:** 2-3 ชม.

---

## 📌 Next Steps After Approval

1. Run Phase 1 tasks (root cause verification)
2. Report findings back
3. Execute Phase 2 (emergency admin)
4. Continue Phase 3-4 after confirmation

---

**Status:** approved — executing now  
**Started:** 2026-08-24
