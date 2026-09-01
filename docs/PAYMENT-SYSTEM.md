# Payment System Documentation

**System:** Slot-based Decimal Tagging Payment  
**Version:** 1.0.0  
**Date:** 2026-08-30  
**Status:** Production Ready

---

## 📋 **Table of Contents**

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [How It Works](#how-it-works)
4. [Setup Guide](#setup-guide)
5. [API Reference](#api-reference)
6. [Troubleshooting](#troubleshooting)
7. [Monitoring](#monitoring)

---

## 🎯 **Overview**

### **What is Decimal Tagging?**

A technique to embed device/invoice identification in the payment amount using decimal places.

**Example:**
```
Base amount: ฿210 (Pro plan, 6 months)
Slot #47 assigned
Tagged amount: ฿210.47

Customer pays ฿210.47
→ System extracts .47
→ Looks up slot 47
→ Matches to device
→ Auto-processes payment
```

### **Why Not Use QR30?**

| Feature | Decimal Tagging | QR30 Bill Payment |
|---------|----------------|-------------------|
| **Cost** | FREE (PromptPay) | ฿500-1,000/month |
| **Setup** | Immediate | Requires bank approval |
| **Bank Support** | All Thai banks | SCB, KBank, BBL only |
| **Scale** | 99 concurrent | Unlimited |
| **Complexity** | Simple | Complex |

**Decision:** Start with decimal tagging, migrate to QR30 if needed (> 1000 concurrent payments unlikely).

---

## 🏗️ **Architecture**

### **System Components**

```
┌─────────────────────────────────────────────────────────┐
│                     Frontend (React)                     │
│  - BillingPage.tsx                                      │
│  - QRPaymentModal.tsx (slot-based)                     │
│  - SlotMonitorPage.tsx (admin)                         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                Services Layer (TypeScript)               │
│  - slotPoolService.ts (99-slot management)             │
│  - qrService.ts (PromptPay QR generation)              │
│  - decimalTagging.ts (amount encoding/decoding)        │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                Database (Supabase/PostgreSQL)            │
│  - cl_payment_slots (99 rows, states: available/       │
│    reserved/paid)                                       │
│  - cl_payment_queue (FIFO when slots full)             │
│  - pg_cron: cleanup_expired_slots() every 5 min        │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│            Webhook Handler (Cloudflare Worker)           │
│  - promptpay-webhook.ts                                │
│  - Receives: bank payment notifications                │
│  - Extracts: slot from amount decimal                  │
│  - Calls: payment-reconcile Edge Function              │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│        Payment Reconciliation (Supabase Edge Fn)         │
│  - payment-reconcile/index.ts                          │
│  - Extends subscription (+6 months)                    │
│  - Unlocks device (Traccar API)                        │
│  - Records payment event                               │
│  - Releases slot (after 5-min buffer)                  │
└─────────────────────────────────────────────────────────┘
```

---

## ⚙️ **How It Works**

### **Flow Diagram**

```
┌─────────────┐
│   Customer  │
│  clicks Pay │
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ 1. Reserve Slot from Pool                │
│    - Query: find available slot (1-99)   │
│    - If found: mark as 'reserved'        │
│    - If not: add to queue                │
│    - Expiry: 15 minutes                  │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ 2. Generate Tagged Amount                │
│    - Base: ฿210                          │
│    - Slot: 47                            │
│    - Result: ฿210.47                     │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ 3. Generate PromptPay QR                 │
│    - Payload: company tax ID + amount    │
│    - Standard Tag 29 (not QR30)          │
│    - Display to customer                 │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ 4. Customer Scans & Pays                 │
│    - Opens banking app                   │
│    - Confirms ฿210.47                    │
│    - Transfers funds                     │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ 5. Bank → Webhook (CF Worker)            │
│    - POST /webhook                       │
│    - Payload: { amount: 210.47, ... }   │
│    - Extract slot: .47 → 47              │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ 6. Lookup Slot Mapping                   │
│    - Query: slot_number = 47             │
│    - Status: must be 'reserved'          │
│    - Get: device_id, invoice_id          │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ 7. Mark Slot as Paid                     │
│    - UPDATE status = 'paid'              │
│    - Set paid_at timestamp               │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ 8. Reconcile Payment (Edge Function)     │
│    - Extend subscription: +6 months      │
│    - Unlock device: Traccar API call     │
│    - Record payment event                │
│    - Update invoice: status = 'paid'     │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ 9. Release Slot (after 5-min buffer)     │
│    - Wait 5 minutes (safety)             │
│    - UPDATE status = 'available'         │
│    - Process queue if any                │
└──────┬───────────────────────────────────┘
       │
       ▼
   ┌──────┐
   │ DONE │
   └──────┘
```

---

## 🚀 **Setup Guide**

### **Prerequisites**

1. Supabase project (PostgreSQL + Edge Functions)
2. Cloudflare Workers account
3. Company PromptPay account (tax ID: 0315562001168)
4. Krungthai Bank account: 0170777294

### **Step 1: Database Setup**

```bash
# Run migrations (order matters!)
supabase db push

# Or manually:
psql $DATABASE_URL -f supabase/migrations/20260830000000_payment_slots.sql
psql $DATABASE_URL -f supabase/migrations/20260830000001_payment_queue.sql
psql $DATABASE_URL -f supabase/migrations/20260830000002_slot_cleanup.sql
```

**Verify:**
```sql
SELECT COUNT(*) FROM cl_payment_slots;
-- Expected: 99

SELECT * FROM cron.job WHERE jobname = 'cleanup-payment-slots';
-- Expected: 1 row, schedule = '*/5 * * * *'
```

### **Step 2: Environment Variables**

**Frontend (`.env.local`):**
```bash
VITE_PROMPTPAY_ID=0315562001168  # Company tax ID
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

**Cloudflare Worker (`wrangler.toml`):**
```toml
name = "promptpay-webhook"
compatibility_date = "2024-01-01"

[vars]
SUPABASE_URL = "https://xxx.supabase.co"

# Set via CLI (secrets):
# wrangler secret put SUPABASE_SERVICE_KEY
# wrangler secret put WEBHOOK_SECRET
```

**Supabase Edge Function:**
```bash
# Set secrets
supabase secrets set TRACCAR_API_URL=https://gps.bellerox.com/api
supabase secrets set TRACCAR_ADMIN_EMAIL=admin@bellerox.com
supabase secrets set TRACCAR_ADMIN_PASSWORD=xxx
```

### **Step 3: Deploy Cloudflare Worker**

```bash
cd infrastructure/cloudflare/workers
wrangler deploy promptpay-webhook.ts

# Output:
# ✅ Deployed to: https://promptpay-webhook.xxx.workers.dev
```

**Test webhook:**
```bash
curl -X POST https://promptpay-webhook.xxx.workers.dev \
  -H "X-Webhook-Secret: YOUR_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 210.47,
    "status": "completed",
    "timestamp": "2026-08-30T12:00:00Z",
    "bank_ref": "TEST123"
  }'

# Expected: {"ok":true,"slot_number":47,"device_id":1234}
```

### **Step 4: Deploy Edge Function**

```bash
supabase functions deploy payment-reconcile

# Output:
# ✅ Deployed function payment-reconcile
```

### **Step 5: Build & Deploy Frontend**

```bash
npm run build
# Deploy to your hosting (Cloudflare Pages, Vercel, etc.)
```

---

## 📡 **API Reference**

### **Frontend Services**

#### **slotPoolService.reserveSlot()**
```typescript
const result = await slotPoolService.reserveSlot(
  deviceId: number,
  invoiceId: string,
  baseAmount: number
);

// Returns:
{
  success: true,
  slot_number: 47,
  expires_at: "2026-08-30T12:15:00Z",
  queued: false
}

// Or if queued:
{
  success: true,
  queued: true,
  queue_position: 3,
  queue_id: "uuid"
}
```

#### **generateTaggedAmount()**
```typescript
import { generateTaggedAmount } from '@/lib/decimalTagging';

const tagged = generateTaggedAmount(210, 47);
// Returns: 210.47
```

#### **extractSlotFromAmount()**
```typescript
import { extractSlotFromAmount } from '@/lib/decimalTagging';

const slot = extractSlotFromAmount(210.47);
// Returns: 47
```

### **Database Functions**

#### **reserve_payment_slot()**
```sql
SELECT * FROM reserve_payment_slot(
  p_device_id := 1234,
  p_invoice_id := 'uuid-here'
);
-- Returns: (slot_number, expires_at)
```

#### **release_payment_slot()**
```sql
SELECT release_payment_slot(47);
-- Returns: void
```

#### **mark_slot_paid()**
```sql
SELECT mark_slot_paid(47);
-- Returns: boolean (true if updated)
```

---

## 🔧 **Troubleshooting**

### **Issue: Slot not released after payment**

**Symptoms:** Slot stays "paid" forever, utilization grows

**Diagnosis:**
```sql
SELECT * FROM cl_payment_slots 
WHERE status = 'paid' 
  AND paid_at < NOW() - INTERVAL '10 minutes';
```

**Fix:**
```sql
-- Manual release
SELECT release_payment_slot(47);

-- Check cron job running
SELECT * FROM cron.job WHERE jobname = 'cleanup-payment-slots';
SELECT * FROM cl_slot_cleanup_log ORDER BY run_at DESC LIMIT 10;
```

---

### **Issue: Queue not processing**

**Symptoms:** Users stuck in queue, slots available

**Diagnosis:**
```sql
SELECT * FROM cl_payment_queue WHERE status = 'waiting';
SELECT * FROM cl_payment_slots WHERE status = 'available';
```

**Fix:**
```sql
-- Trigger manual cleanup
SELECT * FROM trigger_slot_cleanup();

-- Process queue manually
SELECT * FROM process_next_in_queue();
```

---

### **Issue: Payment webhook not received**

**Symptoms:** Customer paid, but no unlock

**Diagnosis:**
1. Check Cloudflare Worker logs
2. Check webhook URL registered with bank
3. Test webhook manually (curl)

**Fix:**
```bash
# Test webhook
curl -X POST https://your-worker.workers.dev \
  -H "X-Webhook-Secret: YOUR_SECRET" \
  -d '{"amount":210.47,"status":"completed","timestamp":"2026-08-30T12:00:00Z"}'
```

---

## 📊 **Monitoring**

### **Slot Monitor Dashboard**

Access: `/admin/slots`

**Metrics:**
- Available slots (green)
- Reserved slots (amber)
- Paid slots (blue)
- Queue length (red)
- Utilization %

**Alerts:**
- 🟡 Warning: > 80% utilization
- 🔴 Critical: Queue length > 5

### **Database Queries**

**Real-time utilization:**
```sql
SELECT * FROM get_slot_stats();
```

**Queue status:**
```sql
SELECT * FROM get_queue_stats();
```

**Recent cleanups:**
```sql
SELECT * FROM v_cleanup_history LIMIT 20;
```

---

## 🎓 **Best Practices**

1. **Monitor utilization daily** — if consistently > 50%, consider scaling strategy
2. **Review queue logs weekly** — queue events = capacity issue
3. **Test webhook monthly** — ensure bank integration still works
4. **Backup slot state** — include in daily database backups
5. **Document edge cases** — track manual resolutions for patterns

---

## 📞 **Support**

**Technical Issues:**
- Check logs: Cloudflare Worker dashboard
- Check database: Supabase logs
- Contact: dev@bellerox.com

**Business Issues:**
- Queue formation (> 5 waiting)
- High utilization (> 90%)
- Contact: ops@bellerox.com

---

**Last Updated:** 2026-08-30  
**Maintained By:** Bellerox Engineering Team
