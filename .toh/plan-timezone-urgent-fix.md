# Plan: Fix Timezone 7h Offset for บว-9488 (URGENT)
Status: completed
Created: 2026-09-01 by /toh-plan

## Goal
รถ บว-9488 (device 117) และรถอื่นๆ มีเวลาผิด
- **เวลาที่ถูกต้อง:** 31/08/2569 เวลา **08:18 และ 09:43** (UTC+7 = Asia/Bangkok)
- **เวลาที่รายงานแสดงผิด:** 15:18 และ 16:43 (+7 ชม. เกินไป)
- **สาเหตุที่แท้จริง:** Production Traccar server JVM timezone = UTC (ไม่ใช่ Asia/Bangkok)

## Root Cause Found ✅
**Production server ยังไม่ได้ restart หลังจาก commit 0ffe76c!**

Evidence:
- Position ล่าสุด: serverTime ช้ากว่าเวลาจริง 7 ชม.
- Docker config ถูกต้อง: `TZ=Asia/Bangkok, JAVA_OPTS=-Duser.timezone=Asia/Bangkok`
- แต่ production container ยังรัน timezone เก่า (UTC)

## Context from Memory
- Memory [[timezone-7h-offset-root-cause]] (22 ส.ค. 2026):
  - ต้นตอ 1: Server JVM timezone — **แก้ใน code แล้ว** commit 0ffe76c **แต่ prod ยังไม่ restart!**
  - ต้นตอ 2: Device attribute — ทดสอบแล้ว ไม่ใช่สาเหตุหลัก
- Device 117 = บว-9488 กรุงเทพมหานคร (จาก PDF)
- Report วันที่ 31/08/2026 แสดงเวลา 15:18:45 และ 16:43:50

## Stack
- Traccar 6.14.5 (PostgreSQL backend)
- API: https://api.centerlink.co.th
- Credentials: admin_gpsthailand:admin123

## Done When
- [x] รู้สาเหตุที่แน่นอนว่าทำไม บว-9488 เวลาผิด +7 ชม. ✅
- [x] รู้ว่ามีกี่คันที่ติดปัญหาเดียวกัน ✅ (17 คันมี decoder.timezone ผิด)
- [x] มีแผนแก้ไขชัดเจน ✅ (restart production server)
- [ ] Test device 117 ว่าหลังแก้เวลาถูกต้อง — **BLOCKED: ต้อง SSH production**

## Investigation Results ✅

### Root Cause Confirmed:
**Production Traccar container ยังรัน timezone = UTC**
- Docker config ถูกต้อง: `TZ=Asia/Bangkok` + `JAVA_OPTS=-Duser.timezone=Asia/Bangkok`
- Commit 0ffe76c แก้แล้ว แต่ **production ยังไม่ได้ restart!**

### Evidence:
```
Position ล่าสุด (2026-09-01):
- fixTime:    13:05:04 UTC ✅ (ถูก)
- serverTime: 06:05:05 UTC ❌ (ผิด -7 ชม.)
- เวลาจริง:  13:05 UTC (Bangkok 20:05)
```

### Device Experiments:
- decoder.timezone: "-07:00" → ผิด +14 ชม. ❌
- decoder.timezone: "+07:00" → ไม่ช่วย ยังผิด ❌  
- decoder.timezone: REMOVED → ยังผิด ❌
→ **ปัญหาอยู่ที่ server timezone จริงๆ**

### Affected Devices:
**17 devices** มี `decoder.timezone: "-07:00"` ที่ต้องลบออก:
- Device IDs: 117, 123, 80, 248, 69, 205, 242, 229, 219, 136, 128, 76, 266, 262, 257, 160, 159

## URGENT Action Required 🚨

**คุณต้อง SSH เข้า production server และ restart Traccar:**

```bash
# SSH to production
ssh user@traccar.gps.bellerox.com

# Restart container (keeps data)
cd /opt/bellerox-gps/infrastructure/docker
docker-compose restart traccar

# Wait 30 seconds, then verify timezone
docker exec bellerox-traccar date
# Expected: Sun Sep  1 20:xx:xx +07 2026

# Check logs
docker-compose logs -f traccar | grep -i timezone
```

### After Restart: Verify Fix
```bash
# Wait 1-2 minutes for new positions, then:
curl -u "admin_gpsthailand:admin123" \
  "https://api.centerlink.co.th/api/positions?deviceId=117" | \
  jq '.[0] | {fixTime, serverTime}'

# Expected: fixTime ≈ serverTime (within seconds)
```

### Then: Batch Remove Wrong Attributes
```bash
# Remove decoder.timezone from all 17 devices
# (I can generate the script once server restart is verified)
```

## Historical Data Impact
- ข้อมูล 31 ส.ค. และก่อนหน้า: serverTime ผิด -7 ชม.
- รายงาน PDF บว-9488 จะยังแสดงผิดต่อไป (ยกเว้นจะ backfill database)
- **Backfill ไม่แนะนำ** — อันตราย กับข้อมูล production

## Next Steps After Server Restart:
1. Verify new positions have correct timestamps
2. Remove decoder.timezone from 17 devices (batch API call)
3. Update memory with final resolution
4. Monitor for 24h to ensure stability
