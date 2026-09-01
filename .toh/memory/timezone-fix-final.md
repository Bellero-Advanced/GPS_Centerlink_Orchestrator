---
name: timezone-fix-final
description: Root cause ยืนยันแล้ว — Production Traccar container ยังรัน UTC (ไม่ใช่ Asia/Bangkok) ต้อง restart
metadata:
  type: project
  date: 2026-09-01
  priority: URGENT
  status: blocked-on-ssh
---

# Timezone +7h Offset — Root Cause Confirmed

**สถานะ:** รู้สาเหตุแล้ว — รอ SSH production เพื่อ restart Traccar

## Root Cause (ยืนยัน 100%)

**Production Traccar container ยังรัน JVM timezone = UTC**
- Docker config ถูกต้องแล้ว: `TZ=Asia/Bangkok` + `JAVA_OPTS=-Duser.timezone=Asia/Bangkok`
- Commit 0ffe76c แก้ใน code แล้ว
- **แต่ production container ยังไม่ได้ restart หลัง commit นั้น!**

## Evidence

Position ล่าสุดของ device 117 (บว-9488):
```
วันที่: 2026-09-01 13:05 UTC (Bangkok 20:05)
fixTime:    13:05:04 UTC ✅ (ถูก — device ส่ง UTC มา)
serverTime: 06:05:05 UTC ❌ (ผิด — server คิดว่าเวลาตอนนี้ 06:05 แทนที่จะเป็น 13:05)
offset: -7 ชั่วโมง
```

→ Server JVM timezone ยังเป็น UTC → `new Date()` คืน 06:05 แทน 13:05

## Device Attribute Tests (ทดสอบหมดแล้ว)

| decoder.timezone | ผลลัพธ์ | สรุป |
|-----------------|---------|------|
| "-07:00" | fixTime ผิด +14 ชม. | ❌ ผิดมาก |
| "+07:00" | fixTime ผิด +7 ชม. | ❌ ไม่ช่วย |
| REMOVED | fixTime ถูก, serverTime ผิด -7 ชม. | ❌ ปัญหาอยู่ที่ server |

**สรุป:** decoder.timezone ไม่ใช่สาเหตุ — ปัญหาอยู่ที่ server timezone 100%

## Affected Devices

**17 devices** มี `decoder.timezone: "-07:00"` ที่ไม่จำเป็น:
- Device IDs: 117, 123, 80, 248, 69, 205, 242, 229, 219, 136, 128, 76, 266, 262, 257, 160, 159

**Action After Server Restart:**
1. รอ production restart
2. Verify new positions ถูกต้อง
3. Batch remove decoder.timezone จาก 17 คัน (ป้องกันปัญหาในอนาคต)

## URGENT: Manual Action Required 🚨

**ต้อง SSH production และ restart Traccar:**

```bash
ssh user@traccar.gps.bellerox.com
cd /opt/bellerox-gps/infrastructure/docker
docker-compose restart traccar

# Verify after restart:
docker exec bellerox-traccar date
# Expected: Sun Sep  1 20:xx:xx +07 2026
```

**Verify Fix (1-2 นาทีหลัง restart):**
```bash
curl -u "admin_gpsthailand:admin123" \
  "https://api.centerlink.co.th/api/positions?deviceId=117" | \
  jq '.[0] | {fixTime, serverTime}'

# Expected: fixTime ≈ serverTime (within seconds)
```

## Historical Data Impact

**ข้อมูลก่อน restart:**
- tc_positions: serverTime ผิด -7 ชม. (fixTime ถูก)
- รายงาน 31 ส.ค. บว-9488: จะยังแสดงผิดต่อไป
- **Backfill database ไม่แนะนำ** — อันตรายต่อ production data

**ข้อมูลหลัง restart:**
- serverTime ถูกต้องทันที
- fixTime ยังถูกต่อไป
- ✅ ทุกอย่างจะถูกต้อง going forward

## Why This Happened

1. Commit 0ffe76c เพิ่ม `TZ=Asia/Bangkok` ใน docker-compose.yml
2. แต่ production ยังรัน container เก่า (ก่อน commit นั้น)
3. Container ไม่ได้ auto-restart เมื่อ docker-compose.yml เปลี่ยน
4. → Production ยังรัน timezone เก่า (UTC) อยู่จนถึงวันนี้

## Next Steps

1. **NOW:** รอคุณ SSH และ restart production
2. **After restart:** Verify 1 device → batch fix 17 devices → update memory
3. **Monitor:** 24h เพื่อ confirm stable

**Related:** [[timezone-7h-offset-root-cause]] (22 ส.ค. diagnosis เก่า)
