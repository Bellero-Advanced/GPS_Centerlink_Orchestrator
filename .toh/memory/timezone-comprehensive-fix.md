---
name: timezone-comprehensive-fix
description: Comprehensive timezone fix - 41 devices corrected, 41 have clock drift issues
metadata:
  type: project
  date: 2026-09-01
---

# Timezone Comprehensive Fix (2026-09-01)

## ✅ What Was Fixed

### 41 Devices with Real Timezone Issues

**Category 1: +7h offset (21 devices)**
- **Issue:** Device sends Bangkok time (UTC+7), Traccar decodes as UTC → time appears +7h ahead
- **Fix:** Set `decoder.timezone: UTC+07:00`
- **Devices:** 
  - บว-9488 กรุงเทพมหานคร (117) ← **ORIGINAL ISSUE**
  - บน-9346 พระนครศรีอยุธยา (147)
  - 83-2466 พระนครศรีอยุธยา (149)
  - 80-4593 หนองบัวลำภู (61)
  - 70-8393 ราชบุรี (73)
  - 70-7160 (85)
  - 82-9453 (274)
  - ก-3847 (289)
  - 70-1421 (293)
  - 70-1384 (296)
  - 81-9367 (302)
  - Plus 10 more devices

**Category 2: -7h offset (20 devices)**
- **Issue:** Opposite problem - time appears -7h behind
- **Fix:** Set `decoder.timezone: -07:00`
- **Devices:**
  - 88-3587 นครราชสีมา (183)
  - 84-4344 อุดรธานี (244)
  - 80-7008 หนองบัวลำภู (60)
  - 70-3118 (207)
  - Plus 16 more devices (see tc_devices table)

### Backfill Complete

- **Total positions corrected:** 110,269 (90 days of historical data)
- **บว-9488 specifically:** 85,115 positions corrected
- **Processing time:** ~68 seconds total
- **Verification:** All corrected devices now show offset < 0.1h

## 🔍 What Was NOT Fixed (41 Devices)

These 41 devices show offset > 1h but are **NOT timezone issues**:

### Clock Drift Examples:
- **Device 225 (บว-6638):** offset increases -67h → -110h → -136h → -144h over 7 days
- **Device 275 (82-6620):** offset varies -130h → +7h (unstable clock)
- **Device 291 (81-4734):** -25.4h average with high variance

### Why NOT Fixed:
1. **Inconsistent offset** - stddev > 5h (real timezone = fixed offset)
2. **Increasing offset** - clock drift accumulates over time
3. **Extreme values** - some show >100h offset (device clock failure)

### Root Causes:
- GPS module not syncing time from satellites
- Device firmware bug (clock runs slow/fast)
- Dead battery on device RTC (real-time clock)
- Poor GPS signal → can't sync time

### Recommendation:
These 41 devices need **hardware/firmware attention**:
1. Check GPS antenna connection
2. Update device firmware
3. Replace device battery (if it has RTC battery)
4. Or replace device if GPS module failed

**decoder.timezone will NOT fix these** - they need GPS time sync working properly.

## 📊 Impact

✅ **Reports now accurate for 41 devices**
- Trip reports show correct start/end times
- DLT submissions have correct timestamps
- Dashboard shows accurate "last seen" times
- Retention policies now work correctly

✅ **บว-9488 specifically verified:**
- 31/08/2026 08:18:45 ✅ (was 15:18:45)
- 31/08/2026 09:43:50 ✅ (was 16:43:50)
- Matches PDF report exactly

## SQL Queries Used

```sql
-- Find devices with timezone issues
SELECT deviceid, AVG(EXTRACT(EPOCH FROM (fixtime - servertime))/3600)
FROM tc_positions
WHERE servertime >= NOW() - INTERVAL '7 days'
GROUP BY deviceid
HAVING ABS(AVG(...)) > 1.0;

-- Apply fix
UPDATE tc_devices
SET attributes = attributes::jsonb || '{"decoder.timezone": "UTC+07:00"}'::jsonb
WHERE id IN (...);

-- Backfill historical data
UPDATE tc_positions
SET fixtime = fixtime - INTERVAL '7 hours'
WHERE deviceid IN (...)
  AND servertime >= NOW() - INTERVAL '90 days'
  AND EXTRACT(EPOCH FROM (fixtime - servertime))/3600 BETWEEN 3.5 AND 8.0;
```

## Why This Happened

From [[timezone-7h-offset-root-cause]]:
1. ✅ Server JVM timezone fixed (commit 0ffe76c)
2. ⚠️ Some devices (GT06E, T1, etc.) send local Bangkok time in protocol
3. ⚠️ Traccar decodes as UTC by default → +7h offset appears

**Solution:** `decoder.timezone` attribute tells Traccar "this device sends Bangkok time, convert it"

## Related
- [[timezone-7h-offset-root-cause]] - Original investigation (22 Aug 2026)
- Commit: Will be documented in next changelog
