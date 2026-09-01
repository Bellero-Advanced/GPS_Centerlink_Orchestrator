---
updated: 2026-09-01
---

# Active Work

## 🎯 Current: Timezone Fix — Deployment Ready ✅

**Status:** Scripts ready, waiting for production SSH  
**Plan:** `.toh/plan-timezone-urgent-fix.md` (completed)  
**Deployment:** `infrastructure/TIMEZONE-FIX-GUIDE.md`

### Root Cause ✅
Production Traccar container ยังรัน JVM timezone = UTC (ไม่ใช่ Asia/Bangkok)
- Docker config ถูกต้องแล้ว (commit 0ffe76c)
- Production ยังไม่ได้ restart หลัง commit นั้น

### Deployment Package Ready ✅
```
infrastructure/scripts/
  ├── fix-timezone-production.sh        ← Main runbook (all-in-one)
  ├── batch-remove-decoder-timezone.sh  ← Clean 17 devices
  ├── check-affected-positions.sql      ← Count wrong rows
  └── backfill-servertime.sql           ← Fix history (optional)

infrastructure/TIMEZONE-FIX-GUIDE.md    ← Complete deployment guide
```

### Deploy Command
```bash
# SSH to production, then:
bash /opt/bellerox-gps/infrastructure/scripts/fix-timezone-production.sh
```

Script will:
1. Backup database
2. Restart Traccar with Asia/Bangkok timezone
3. Verify timestamps correct
4. Remove decoder.timezone from 17 devices
5. Check historical data
6. Offer backfill (dry-run first)

### Evidence
- Device 117 offset: 6-7 hours (confirmed wrong)
- 17 devices have wrong decoder.timezone attribute
- Historical data affected (query will count exact rows)

---

## 📌 Next After Deploy
1. Verify new positions correct (fixTime ≈ serverTime)
2. Test report 31/08/2026 for บว-9488
3. Monitor 24h for stability

---

## 📌 Previous Work
**2026-08-25:** DLT ส่งครบทุกคัน + Auto-index Partition ✅
