# Payment System Testing Checklist

**System:** Slot-based decimal tagging payment system  
**Date:** 2026-08-30  
**Tester:** ___________

---

## 🎯 **Test Scenarios**

### **Scenario 1: Normal Payment Flow** ✅

**Steps:**
1. Navigate to Billing page
2. Click "ชำระเงิน" on a vehicle
3. Verify QR modal shows:
   - ✅ Tagged amount (e.g., ฿210.47)
   - ✅ Slot number displayed
   - ✅ Warning text about exact amount
   - ✅ QR code image renders
4. Simulate payment (webhook call)
5. Verify:
   - ✅ Modal shows "ชำระเงินสำเร็จ"
   - ✅ Device unlocks
   - ✅ Subscription extended (+6 months)
   - ✅ Slot released after 5 min

**Expected Result:** Payment processed, device unlocked, slot reused

---

### **Scenario 2: Concurrent Payments (10 users)** ✅

**Steps:**
1. Open 10 browser tabs
2. Click "ชำระเงิน" in each tab simultaneously
3. Verify each tab gets unique slot (01-10)
4. Check slot monitor shows 10 reserved slots
5. Process payments sequentially
6. Verify all slots released

**Expected Result:** All 10 users get unique slots, no collision

---

### **Scenario 3: Queue System (99+ concurrent)** ⚠️

**Steps:**
1. Reserve all 99 slots (script/manual)
2. Attempt 100th payment
3. Verify:
   - ✅ QR modal shows queue UI
   - ✅ Queue position displayed (#1, #2, etc.)
   - ✅ Estimated wait time shown
4. Release one slot
5. Verify:
   - ✅ Queue processes automatically
   - ✅ User #1 gets QR code
   - ✅ Queue position updates

**Expected Result:** Queue system works, FIFO order maintained

**Probability:** < 1% in production (max 5-10 concurrent typical)

---

### **Scenario 4: Expired Slot** ✅

**Steps:**
1. Generate QR (reserves slot for 15 min)
2. Wait 16 minutes without paying
3. Verify cron job releases slot (check at 5-min intervals)
4. Attempt to pay with expired slot
5. Verify:
   - ✅ Payment rejected (slot not reserved)
   - ✅ Admin sees "expired" in logs

**Expected Result:** Expired slots auto-released, payment requires manual resolution

---

### **Scenario 5: Amount Mismatch** ❌

**Steps:**
1. QR shows ฿210.47
2. Customer pays ฿210.50 (rounded)
3. Webhook receives wrong slot (50 instead of 47)
4. Verify:
   - ✅ Payment not auto-matched
   - ✅ Admin notification
   - ✅ Manual resolution UI available

**Expected Result:** Wrong amount rejected, admin can manually match

---

### **Scenario 6: Device ID Collision** ⚠️

**Setup:**
- Device A: ID = 1047 → suffix = 47
- Device B: ID = 2147 → suffix = 47

**Steps:**
1. Both devices due for payment
2. Customer A pays ฿210.47
3. System finds 2 devices ending in "47"
4. Verify:
   - ✅ Payment flagged as ambiguous
   - ✅ Admin sees both options
   - ✅ Admin can manually select correct device

**Expected Result:** Collision detected, admin resolves manually

**Mitigation:** Rare with 99 slots + sequential assignment

---

### **Scenario 7: Slot Monitor** ✅

**Steps:**
1. Navigate to `/admin/slots` (or equivalent)
2. Verify dashboard shows:
   - ✅ Available count (green)
   - ✅ Reserved count (amber)
   - ✅ Paid count (blue)
   - ✅ Queue count (red)
   - ✅ Utilization % bar
   - ✅ 99-slot grid with color coding
3. Reserve a slot → verify grid updates
4. Enable auto-refresh → verify 5s polling

**Expected Result:** Real-time monitoring works

---

### **Scenario 8: Webhook Verification** ✅

**Steps:**
1. Send test webhook to CF Worker:
   ```bash
   curl -X POST https://your-worker.workers.dev/webhook \
     -H "X-Webhook-Secret: YOUR_SECRET" \
     -H "Content-Type: application/json" \
     -d '{
       "amount": 210.47,
       "status": "completed",
       "timestamp": "2026-08-30T12:00:00Z",
       "bank_ref": "TEST123"
     }'
   ```
2. Verify:
   - ✅ Slot 47 marked as paid
   - ✅ Edge Function called
   - ✅ Subscription extended
   - ✅ Device unlocked
   - ✅ Payment event recorded

**Expected Result:** Webhook chain works end-to-end

---

### **Scenario 9: Manual Admin Override** ✅

**Steps:**
1. Create unmatched payment scenario
2. Admin opens BillingAdminPage
3. Click "Resolve" on ambiguous payment
4. Select correct device from dropdown
5. Confirm
6. Verify:
   - ✅ Payment applied to selected device
   - ✅ Subscription extended
   - ✅ Device unlocked

**Expected Result:** Admin can manually resolve edge cases

---

### **Scenario 10: Slot Reuse** ✅

**Steps:**
1. Reserve slot #47
2. Complete payment
3. Wait 5 minutes
4. Verify slot #47 released (status = available)
5. Reserve slot again
6. Verify same slot assigned to new payment

**Expected Result:** Slots reuse correctly, no leaks

---

## 🔧 **Performance Tests**

### **Load Test: 50 Concurrent Requests**
```bash
# Apache Bench
ab -n 50 -c 50 -p payment.json -T application/json \
  https://api.bellerox.com/billing/reserve-slot
```

**Expected:**
- ✅ All 50 requests succeed
- ✅ 50 unique slots assigned
- ✅ < 2s response time
- ✅ No slot collisions

---

### **Stress Test: 100 Concurrent (Queue Formation)**
```bash
ab -n 100 -c 100 -p payment.json -T application/json \
  https://api.bellerox.com/billing/reserve-slot
```

**Expected:**
- ✅ First 99 get slots
- ✅ Last 1 queued
- ✅ Queue processed when slot released
- ✅ No database deadlocks

---

## 🛡️ **Security Tests**

### **Test 1: Webhook Secret Validation**
```bash
# Send webhook without secret
curl -X POST https://worker.dev/webhook -d '{...}'

# Expected: 401 Unauthorized
```

### **Test 2: SQL Injection in Slot Query**
```bash
# Try injecting SQL in slot_number parameter
curl "https://api.../slots?slot_number=1'; DROP TABLE--"

# Expected: Sanitized, no SQL execution
```

### **Test 3: Rate Limiting**
```bash
# Spam slot reservation requests
for i in {1..1000}; do
  curl https://api.../billing/reserve-slot &
done

# Expected: Rate limit kicks in, some 429 responses
```

---

## 📊 **Database Verification**

### **Check Slot Integrity**
```sql
-- All slots 1-99 should exist
SELECT COUNT(*) FROM cl_payment_slots;
-- Expected: 99

-- No duplicate slot numbers
SELECT slot_number, COUNT(*) 
FROM cl_payment_slots 
GROUP BY slot_number 
HAVING COUNT(*) > 1;
-- Expected: 0 rows

-- No orphaned reserved slots (> 30 min old)
SELECT * FROM cl_payment_slots 
WHERE status = 'reserved' 
  AND reserved_at < NOW() - INTERVAL '30 minutes';
-- Expected: 0 rows (cron should clean)
```

### **Check Queue Processing**
```sql
-- No stuck queue entries
SELECT * FROM cl_payment_queue 
WHERE status = 'processing' 
  AND requested_at < NOW() - INTERVAL '10 minutes';
-- Expected: 0 rows

-- Queue FIFO order maintained
SELECT id, requested_at 
FROM cl_payment_queue 
WHERE status = 'waiting' 
ORDER BY requested_at;
-- Expected: chronological order
```

---

## ✅ **Sign-off**

| Test Suite | Status | Notes |
|------------|--------|-------|
| Normal Flow | ☐ Pass ☐ Fail | _____ |
| Concurrent | ☐ Pass ☐ Fail | _____ |
| Queue | ☐ Pass ☐ Fail | _____ |
| Edge Cases | ☐ Pass ☐ Fail | _____ |
| Performance | ☐ Pass ☐ Fail | _____ |
| Security | ☐ Pass ☐ Fail | _____ |

**Overall Status:** ☐ Ready for Production ☐ Needs Fixes

**Tested by:** _________________  
**Date:** _________________  
**Sign-off:** _________________
