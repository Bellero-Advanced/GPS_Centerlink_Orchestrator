# Enrollment Testing Checklist

**Date:** 2026-08-31  
**Task:** Auto-enroll all vehicles for billing

---

## ✅ Pre-flight Checks

- [x] Script created: `scripts/enroll-all-vehicles.ts`
- [x] CLI runner created: `scripts/run-enrollment.sh`
- [x] Admin features verified: change plan, mark paid still exist

---

## 📋 Manual Testing Steps

### **Step 1: Dry Run (Review)**
```bash
# Review script logic
cat scripts/enroll-all-vehicles.ts

# Expected behavior:
# 1. Fetch all devices from Traccar
# 2. Filter: only devices with IMEI
# 3. Skip devices already enrolled
# 4. Create subscriptions with:
#    - start_date: 2026-09-15
#    - end_date: 2027-03-15
#    - plan_id: pro
#    - status: active
```

### **Step 2: Run Enrollment**
```bash
# Set environment variables in .env.local:
TRACCAR_ADMIN_EMAIL=admin@bellerox.com
TRACCAR_ADMIN_PASSWORD=xxx
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxx

# Run script
./scripts/run-enrollment.sh

# Expected output:
# ✅ Authenticated
# ✅ Found X devices, Y with IMEI
# ✅ Created N new subscriptions
# 🎉 Enrollment complete
```

### **Step 3: Verify in Database**
```sql
-- Check subscription count
SELECT COUNT(*) FROM billing_subscriptions;

-- Check date ranges
SELECT 
  COUNT(*) as total,
  MIN(start_date) as earliest_start,
  MAX(end_date) as latest_end,
  plan_id,
  status
FROM billing_subscriptions
GROUP BY plan_id, status;

-- Expected:
-- start_date: all 2026-09-15
-- end_date: all 2027-03-15
-- plan_id: pro
-- status: active
```

### **Step 4: Test Admin Features**

**A. Change Plan**
1. Open `/admin/billing` (or equivalent)
2. Find a subscription
3. Change plan: Pro → Basic
4. Verify: plan updated, price changed

**B. Mark Paid**
1. Find an invoice
2. Click "Mark as Paid"
3. Verify: status → paid, paid_at set

**C. Adjust Dates**
1. Find a subscription
2. Edit end_date field (if available)
3. Save
4. Verify: date updated

---

## ✅ Success Criteria

- [ ] Script runs without errors
- [ ] All devices with IMEI enrolled
- [ ] No duplicate subscriptions created
- [ ] Start date = 2026-09-15 for all
- [ ] End date = 2027-03-15 for all
- [ ] Admin can change plan
- [ ] Admin can mark paid
- [ ] Admin can adjust dates
- [ ] No breaking changes to existing features

---

## 🚀 Production Deployment

**After testing passes:**

1. **Run script on production:**
   ```bash
   # SSH to production server
   cd /path/to/app
   ./scripts/run-enrollment.sh
   ```

2. **Verify count:**
   ```bash
   # Should match Traccar device count
   psql -c "SELECT COUNT(*) FROM billing_subscriptions;"
   ```

3. **Monitor for issues:**
   - Check Supabase logs
   - Check Sentry (if configured)
   - Test a few payment flows

---

## 📝 Notes

- Script is **idempotent** — safe to run multiple times
- Only creates subscriptions for devices not already enrolled
- Default plan: Pro (฿210/6 months)
- Admin can adjust individual subscriptions after enrollment

---

**Tester:** ___________  
**Date:** ___________  
**Status:** ☐ Pass ☐ Fail  
**Notes:** ___________
