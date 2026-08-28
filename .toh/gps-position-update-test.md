# GPS Position Update Test Plan

**Date:** 2026-08-28  
**Bug Report:** "รถผมวิ่งงานหมดแล้วแต่ GPS ยังจอดกองกันอยู่ที่บริษัทเลย ขึ้นสถานะ แต่จีพีเอสไม่เคลื่อนไหว"

---

## Test Objective

Verify that vehicles moving in the field receive position updates within 30 seconds, even when:
1. Traccar WebSocket cache doesn't include the vehicle
2. Vehicle was added before Traccar restart
3. WebSocket sends `device` updates but not `position` updates

---

## Test Setup

### Prerequisites
- ✅ Build passes (`npm run build`)
- ✅ Dev server running (`npm run dev`)
- ✅ LiveMapPage accessible at http://localhost:5173/app/map
- ✅ At least 1 test vehicle available (real device or simulator)

### Test Environment
- Browser: Chrome/Safari with DevTools open
- Console tab visible (for position monitor logs)
- Network tab monitoring (optional)

---

## Test Cases

### Test Case 1: Position Monitor Diagnostics

**Steps:**
1. Open http://localhost:5173/app/map
2. Open browser DevTools → Console tab
3. Wait 10 seconds for first monitor log

**Expected Output:**
```
[Position Monitor] 214 devices, 22 cached positions
[Position Monitor] ⚠️ 192 devices missing from cache (98 online)
[Position Monitor] 🔴 Gap device IDs: [23, 24, 25, ...]
```

**Pass Criteria:**
- ✅ Console shows position coverage stats every 10s
- ✅ Gap device count matches (cached < total devices)
- ✅ Online gap devices identified

**Result:** ⬜ Not tested yet

---

### Test Case 2: WebSocket Fallback Trigger

**Scenario:** Vehicle sends GPS packet but not in cache

**Steps:**
1. Identify a vehicle with `status='online'` but stale position
2. Verify in console: `[Position Monitor] ⚠️ X devices missing from cache`
3. Wait for vehicle to send next GPS packet (usually 30s interval)
4. Watch console for fallback trigger

**Expected Behavior:**
- Within 1-2 seconds of device update:
  - Position query invalidated
  - PostgreSQL fetch triggered
  - Position updates on map

**Expected Console:**
```
[WS] Device update received: device 122
[WS] Gap detected: device 122 online but not in cache
[Query] Invalidating positionKeys.byDeviceIds("122")
[Query] Fetching position from PostgreSQL
```

**Pass Criteria:**
- ✅ Position updates within 2 seconds of device WS message
- ✅ Coordinates change on map
- ✅ No console errors

**Result:** ⬜ Not tested yet

---

### Test Case 3: Emergency Polling for Stale-Online Paradox

**Scenario:** Vehicle showing as "Moving" but coordinates frozen

**Steps:**
1. Find vehicle with:
   - Status badge: "เคลื่อนที่" (Moving) or "ออนไลน์" (Online)
   - Position timestamp: > 10 minutes old
   - Coordinates: Not updating
2. Wait 10 seconds
3. Observe console and map

**Expected Console:**
```
[Emergency Refresh] 1 vehicles in stale-online paradox
[Emergency Refresh] Updated 1 positions
```

**Expected Behavior:**
- Within 10 seconds:
  - Emergency polling triggers
  - Position fetched from PostgreSQL
  - Coordinates update on map
  - Vehicle moves to correct location

**Pass Criteria:**
- ✅ Stale-online vehicles identified in console
- ✅ Position updates within 10 seconds
- ✅ Coordinates reflect actual vehicle location
- ✅ Emergency polling continues every 10s until position fresh

**Result:** ⬜ Not tested yet

---

### Test Case 4: Real Vehicle Movement (Customer Scenario)

**Scenario:** Reproduce exact customer report

**Initial State:**
- Vehicle parked at company location (old position)
- Status badge shows "จอดดับเครื่อง" (Stopped) or "ออฟไลน์" (Offline)
- Coordinates: Company address

**Action:**
- Vehicle starts moving (driver starts engine, drives away)
- GPS device sends packets to Traccar

**Expected Timeline:**
1. **0-5 seconds:** Status badge updates to "เคลื่อนที่" (Moving)
2. **1-10 seconds:** Coordinates start updating (WS fallback or emergency polling)
3. **10-30 seconds:** Vehicle marker moves on map
4. **Continuous:** Position updates every 10-30 seconds as vehicle moves

**Pass Criteria:**
- ✅ Status badge updates within 5 seconds
- ✅ Coordinates update within 30 seconds
- ✅ Vehicle marker moves continuously (not frozen)
- ✅ Speed shows correctly (> 0 km/h when moving)
- ✅ Last seen timestamp stays fresh (< 1 minute old)

**Result:** ⬜ Not tested yet

---

### Test Case 5: Multiple Vehicles Simultaneously

**Scenario:** Multiple vehicles in stale-online state

**Steps:**
1. Identify 5+ vehicles with stale positions but online status
2. Verify console shows: `[Emergency Refresh] 5 vehicles in stale-online paradox`
3. Wait 10 seconds
4. Check all 5 vehicles on map

**Expected Behavior:**
- All 5 vehicles refresh within 10 seconds
- Console shows: `[Emergency Refresh] Updated 5 positions`
- Map markers update to correct locations
- No performance degradation (smooth scrolling/zooming)

**Pass Criteria:**
- ✅ All stale-online vehicles identified
- ✅ All positions update within 10 seconds
- ✅ No query timeouts or errors
- ✅ UI remains responsive

**Result:** ⬜ Not tested yet

---

### Test Case 6: WebSocket Disconnect Recovery

**Scenario:** WebSocket disconnects, fallback system takes over

**Steps:**
1. Vehicle moving normally (positions updating)
2. Simulate WS disconnect (close browser DevTools Network throttling, or server restart)
3. Wait 30 seconds
4. Verify positions still update

**Expected Behavior:**
- WebSocket status: "disconnected" or "failed"
- Emergency polling continues (10s interval)
- Normal polling continues (30s interval)
- Positions keep updating (slightly slower, but not frozen)

**Pass Criteria:**
- ✅ Positions update even without WebSocket
- ✅ Max staleness: 30 seconds (polling interval)
- ✅ No UI errors or blank screens
- ✅ Console shows: `[GPS WebSocket] Switched to polling-only mode`

**Result:** ⬜ Not tested yet

---

## Success Metrics

**Fix Verified When:**
- ✅ Test Case 1: Position monitor shows gap detection
- ✅ Test Case 2: WS fallback triggers < 2s
- ✅ Test Case 3: Emergency polling updates < 10s
- ✅ Test Case 4: Customer scenario passes (status + position update)
- ✅ Test Case 5: Multiple vehicles handle correctly
- ✅ Test Case 6: WS disconnect doesn't freeze positions

**Customer Satisfaction:**
- ✅ "GPS ตำแหน่งเคลื่อนไหวตามรถจริง" (GPS position moves with actual vehicle)
- ✅ "ไม่มีรถค้างที่บริษัทแล้ว" (No vehicles frozen at company anymore)
- ✅ "เห็นตำแหน่งเรียลไทม์ภายใน 10-30 วินาที" (See real-time position within 10-30 seconds)

---

## Manual Test Results

### Test Date: __________

**Tester:** __________

**Results:**

**Test Case 1 (Position Monitor):**
- Console output: _______________________
- Status: ⬜ Pass / ⬜ Fail
- Notes: _______________________

**Test Case 2 (WS Fallback):**
- Trigger latency: _______ seconds
- Status: ⬜ Pass / ⬜ Fail
- Notes: _______________________

**Test Case 3 (Emergency Polling):**
- Vehicles detected: _______
- Update latency: _______ seconds
- Status: ⬜ Pass / ⬜ Fail
- Notes: _______________________

**Test Case 4 (Customer Scenario):**
- Status update: _______ seconds
- Position update: _______ seconds
- Status: ⬜ Pass / ⬜ Fail
- Notes: _______________________

**Test Case 5 (Multiple Vehicles):**
- Vehicles tested: _______
- All updated: ⬜ Yes / ⬜ No
- Status: ⬜ Pass / ⬜ Fail
- Notes: _______________________

**Test Case 6 (WS Disconnect):**
- Fallback worked: ⬜ Yes / ⬜ No
- Max staleness: _______ seconds
- Status: ⬜ Pass / ⬜ Fail
- Notes: _______________________

---

## Known Limitations

**Out of Scope (Hardware/Network Issues):**
- ❌ GPS device not sending packets at all (SIM/hardware fault)
- ❌ Device never connected to Traccar (wrong server IP)
- ❌ Position timestamp shows future date (device clock wrong)

**These require field support, not code fixes.**

**In Scope (Software Fixes):**
- ✅ Device sends packets but position doesn't update (cache gap)
- ✅ Status updates but coordinates freeze (WS position gap)
- ✅ Vehicle stale-online paradox (emergency polling)

---

## Rollback Plan

If fix causes issues:
1. Revert commit: `git revert <commit-hash>`
2. Rollback files:
   - `src/hooks/useTraccarWebSocket.ts`
   - `src/hooks/useEmergencyPositionRefresh.ts`
   - `src/hooks/usePositionMonitor.ts`
   - `src/pages/LiveMapPage.tsx`
3. Redeploy previous version
4. Document issue in `.toh/gps-position-update-test.md`
