# ⚠️ Conflict Resolution Guide

**Date:** 2026-08-29  
**Issue:** Multiple development sessions running simultaneously  
**Impact:** Potential file conflicts during deployment

---

## 🔍 Detected Conflicts

### 1. Uncommitted Changes (Critical)
**Files affected:**
- 20 new migrations (016-028)
- New API routes (whitelabel, analytics, health)
- Mobile app folder
- Documentation
- GitHub Actions

**Risk:** High - Could lose work or cause merge conflicts

**Resolution:**
```bash
# 1. Check current changes
git status

# 2. Commit all work
git add .
git commit -m "feat: Phase 0-11 complete + Mobile MVP

- Added 20 migrations (RBAC, performance, analytics)
- Implemented multi-tenant mobile app
- Added monitoring and security features
- Complete documentation

Co-Authored-By: Claude <noreply@anthropic.com>"

# 3. Tag release
git tag v2.0.0-rc1
git push origin main --tags
```

### 2. Mobile App Submodule (Medium)
**Status:** `m bellerox-gps-mobile` (modified submodule)

**Risk:** Medium - Submodule not properly tracked

**Resolution:**
```bash
# Option A: Commit submodule changes
cd bellerox-gps-mobile
git add .
git commit -m "Mobile app v1.0.0 - MVP complete"
cd ..
git add bellerox-gps-mobile
git commit -m "Update mobile app to v1.0.0"

# Option B: Remove submodule, treat as regular folder
git rm --cached bellerox-gps-mobile
git add bellerox-gps-mobile
git commit -m "Convert mobile app from submodule to regular folder"
```

### 3. Concurrent Web App Sessions (Low)
**Issue:** Another session may be modifying web app

**Risk:** Low - Different files typically

**Resolution:**
```bash
# Before deploy, check for conflicts
git fetch origin
git status

# If behind origin
git pull --rebase origin main

# Resolve any conflicts
git status
# Edit conflicted files
git add .
git rebase --continue
```

---

## 🔐 File Lock Strategy

### Critical Files (Lock During Deploy)
These files should NOT be modified during deployment:

**Database:**
- `migrations/*.sql` - Migration files
- `scripts/backup-database.sh`
- `scripts/restore-database.sh`

**API Server:**
- `bellerox-gps-web/server/index.js`
- `bellerox-gps-web/server/routes/*.js`

**Configuration:**
- `eas.json`
- `app.config.js`
- `config/tenants.json`

**Lock Command:**
```bash
# Create lock file
touch .DEPLOYMENT_IN_PROGRESS

# Check before editing
if [ -f .DEPLOYMENT_IN_PROGRESS ]; then
  echo "⚠️ Deployment in progress! Do not edit files."
  exit 1
fi
```

---

## 📂 Safe vs Unsafe to Modify

### ✅ Safe to Modify During Deploy
These won't affect production:
- Documentation (*.md files)
- Test files
- Development configs
- Local scripts

### ⚠️ Unsafe to Modify During Deploy
These could break production:
- Migration files
- API routes
- Database schemas
- Build configs
- Environment variables

---

## 🔄 Merge Strategy

### If Other Session Has Changes

**Scenario 1: No Conflicts**
```bash
git pull origin main
# Auto-merge successful ✅
git push origin main
```

**Scenario 2: Simple Conflicts**
```bash
git pull origin main
# CONFLICT in file.txt

# Edit file.txt, resolve conflicts
git add file.txt
git commit -m "Merge: Resolve conflicts"
git push origin main
```

**Scenario 3: Complex Conflicts**
```bash
# Abort merge
git merge --abort

# Stash your changes
git stash save "Pre-deploy changes"

# Pull clean
git pull origin main

# Apply your changes
git stash pop

# Resolve conflicts
git add .
git commit -m "Merge: Apply pre-deploy changes"
```

---

## 🚨 Emergency Procedures

### If Deploy Starts With Conflicts

**STOP IMMEDIATELY**
```bash
# 1. Cancel deployment
echo "⚠️ DEPLOYMENT CANCELLED - CONFLICTS DETECTED"

# 2. Notify team
# Send message: "Deployment paused due to conflicts"

# 3. Resolve conflicts first
git status
# Fix all conflicts

# 4. Test locally
npm run build

# 5. Resume deployment
echo "✅ Conflicts resolved, resuming..."
```

### If Conflicts Detected Mid-Deploy

**Rollback & Fix**
```bash
# 1. Rollback deployment
./scripts/rollback.sh

# 2. Fix conflicts offline
git pull origin main
# Resolve conflicts

# 3. Test thoroughly
npm run build
npm test

# 4. Re-deploy
./scripts/deploy.sh
```

---

## 📋 Pre-Deploy Conflict Check

Run this before starting deployment:

```bash
#!/bin/bash
# pre-deploy-check.sh

echo "🔍 Checking for conflicts..."

# Check uncommitted changes
if [[ -n $(git status -s) ]]; then
  echo "⚠️ Uncommitted changes detected:"
  git status -s
  echo ""
  echo "Action: Commit or stash before deploy"
  exit 1
fi

# Check if behind origin
git fetch origin
BEHIND=$(git rev-list HEAD..origin/main --count)
if [ $BEHIND -gt 0 ]; then
  echo "⚠️ Behind origin/main by $BEHIND commits"
  echo "Action: git pull origin main"
  exit 1
fi

# Check if ahead of origin
AHEAD=$(git rev-list origin/main..HEAD --count)
if [ $AHEAD -gt 0 ]; then
  echo "⚠️ Ahead of origin/main by $AHEAD commits"
  echo "Action: git push origin main"
  exit 1
fi

# Check for lock file
if [ -f .DEPLOYMENT_IN_PROGRESS ]; then
  echo "⚠️ Deployment already in progress!"
  exit 1
fi

echo "✅ No conflicts detected"
echo "✅ Safe to proceed with deployment"
exit 0
```

**Usage:**
```bash
chmod +x pre-deploy-check.sh
./pre-deploy-check.sh
```

---

## 🎯 Recommended Actions NOW

### Immediate (Do Before Deploy)

1. **Commit Everything**
```bash
git add .
git commit -m "Production ready: Phase 0-11 + Mobile MVP"
```

2. **Push to Remote**
```bash
git push origin main
```

3. **Verify Clean State**
```bash
git status
# Should show: "nothing to commit, working tree clean"
```

4. **Tag Release**
```bash
git tag v2.0.0
git push origin --tags
```

### During Deploy

1. **Create Lock File**
```bash
touch .DEPLOYMENT_IN_PROGRESS
git add .DEPLOYMENT_IN_PROGRESS
git commit -m "Lock: Deployment in progress"
```

2. **Monitor for Changes**
```bash
# In separate terminal
watch -n 10 'git fetch origin && git status'
```

3. **Release Lock After**
```bash
rm .DEPLOYMENT_IN_PROGRESS
git add .DEPLOYMENT_IN_PROGRESS
git commit -m "Unlock: Deployment complete"
```

---

## 📊 Conflict Risk Assessment

### Current Risk Level: **MEDIUM ⚠️**

**Factors:**
- ❌ Uncommitted changes (High risk)
- ❌ Submodule status unclear (Medium risk)
- ❌ Multiple sessions active (Medium risk)
- ✅ No merge conflicts detected (Low risk)
- ✅ Code builds successfully (Low risk)

**Mitigation Required:**
1. Commit all changes immediately
2. Coordinate with other sessions
3. Create deployment lock
4. Test merge before deploy

---

## ✅ Conflict-Free Deployment Checklist

- [ ] All changes committed
- [ ] Working tree clean (`git status`)
- [ ] Pushed to origin
- [ ] No untracked files
- [ ] Submodule status clear
- [ ] No other sessions editing critical files
- [ ] Deployment lock created
- [ ] Team notified

**When all checked: ✅ SAFE TO DEPLOY**

---

**Last Updated:** 2026-08-29  
**Next Review:** Before production deployment
