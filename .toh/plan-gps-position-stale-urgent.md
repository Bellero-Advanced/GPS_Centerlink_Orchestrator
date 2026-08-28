# 🚨 GPS Position Stale — Urgent Customer Bug Fix

**Status:** approved  
**Created:** 2026-08-28  
**Priority:** P0 (Customer-reported production bug)  
**Approved:** 2026-08-28

---

## 🎯 Goal

**Customer Report:** "รถผมวิ่งงานหมดแล้วแต่ GPS ยังจอดกองกันอยู่ที่บริษัทเลย ขึ้นสถานะ แต่จีพีเอสไม่เคลื่อนไหว ระบบค้างหรือป่าว"

**Translation:** Vehicles are working in the field but GPS shows them parked at company. Status badge shows "Moving" but position doesn't update.

**Root Cause:** WebSocket position updates NOT reaching LiveMapPage — vehicles missing from Traccar's in-memory cache don't receive real-time WS pushes.

**Impact:**
- Customer sees STALE positions (hours/days old)
- Status badge CORRECT (from device WS) but coordinates WRONG
- Critical safety issue: Can't locate moving vehicles

**Solution:**
1. **Verify WS position updates** reach React Query cache
2. **Force fallback refresh** on WS device updates (if no matching position)
3. **Add real-time diagnostics** to detect WS position gaps
4. **Emergency polling** for devices with stale positions + online status

---

## 🏗️ Stack

- **Hooks:** `useTraccarWebSocket.ts`, `useDevices.ts`
- **Services:** `traccarService.ts`
- **Components:** `LiveMapPage.tsx`, `FloatingVehiclePanel.tsx`
- **Lib:** `vehicleStatus.ts`

---

## 📄 Pages Affected

- **LiveMapPage** (primary) — real-time map
- **FleetPage** — vehicle list view
- **FloatingVehiclePanel** — vehicle cards

---

## ✅ Done When

- [x] Root cause confirmed (WebSocket position gap)
- [ ] WS invalidates fallback queries on device update
- [ ] Emergency polling for stale-but-online devices
- [ ] Console diagnostics show WS position coverage
- [ ] Customer scenario tested: vehicle moving → position updates < 30s
- [ ] Build passes (`npm run build`)
- [ ] Memory updated with fix

---

## 📋 Phases

### Phase 1: Root Cause Verification

**Goal:** Confirm WebSocket position updates reach cache for ALL devices

**Current State Analysis:**

✅ **What Works:**
- `useVehiclesWithPositions()` has 3-layer fallback (cache → positionId → deviceId)
- `useFallbackPositions()` recovers 121/214 missing devices from PostgreSQL
- `computeVehicleStatus()` correctly uses `livePos` only for status/speed

❌ **What's Broken:**
- **WebSocket updates positions cache** (`positionKeys.current`)
- **BUT** devices NOT in cache don't have their positions streamed
- **Result:** Moving vehicle gets `device` WS update (status changes) but NO `position` WS update (coordinates frozen)

📊 **Evidence from Code:**

```typescript
// useTraccarWebSocket.ts:82-89
if (msg.positions?.length) {
  queryClient.setQueryData<TraccarPosition[]>(
    positionKeys.current,
    (old = []) => {
      const map = new Map(old.map((p) => [p.deviceId, p]));
      for (const pos of msg.positions!) map.set(pos.deviceId, pos);
      return Array.from(map.values());
    },
  );
}
```

**Problem:** If `vehicle.id` not in `positions` cache initially → WS `msg.positions` won't include it → cache stays empty for that device → coordinates never update

**T001** Create diagnostic script
- File: `src/lib/__tests__/wsPositionCoverage.test.ts`
- Test: Load devices + positions, compare device.id vs cached position.deviceId
- Assert: Log devices with `status='online'` but NO cached position
- This confirms the gap size in production

**✓ Checkpoint 1:** Test runs, prints diagnostic output

---

### Phase 2: WebSocket Fallback Trigger

**Goal:** When WS sends `device` update but NO matching `position` → invalidate fallback queries

**Strategy:**
- WebSocket receives `msg.devices` (device status/lastUpdate)
- Check if device is `online` but NOT in `positionKeys.current` cache
- If gap detected → invalidate `positionKeys.byIds()` / `positionKeys.byDeviceIds()` for that device
- This forces React Query to refetch from PostgreSQL via fallback

**T002** Enhance `useTraccarWebSocket.ts` onmessage handler
- After processing `msg.devices`, check for position gaps
- For each device in `msg.devices`:
  ```typescript
  const cachedPos = queryClient.getQueryData<TraccarPosition[]>(positionKeys.current);
  const deviceHasPosition = cachedPos?.some(p => p.deviceId === device.id);
  if (device.status === 'online' && !deviceHasPosition) {
    // Gap detected: device online but no cached position
    // Force fallback refresh
    queryClient.invalidateQueries({ 
      queryKey: positionKeys.byDeviceIds(device.id.toString())
    });
  }
  ```

**T003** Add emergency refresh interval
- In `useVehiclesWithPositions()`:
- Detect vehicles with `status='online'` + `isStale=true` (paradox state)
- For those vehicles, force `useDeviceIdPositions()` refresh every 10s (aggressive)
- Normal vehicles stay at 30s polling
- This ensures moving vehicles NEVER freeze for > 10s

**✓ Checkpoint 2:** WS triggers fallback invalidation, coordinates update within 30s

---

### Phase 3: Real-Time Position Monitoring

**Goal:** Add console diagnostics to detect WS position gaps in real-time

**T004** Add `usePositionMonitor()` hook (dev mode only)
- File: `src/hooks/usePositionMonitor.ts`
- Every 10s: compare devices vs cached positions
- Log to console:
  ```
  [Position Monitor] 206 devices, 189 cached positions
  [Position Monitor] ⚠️ 17 devices missing from cache (12 online)
  [Position Monitor] 🔴 Gap devices: [122, 145, 167, ...] (IDs)
  ```
- Only runs in dev mode (`import.meta.env.DEV`)

**T005** Add to `LiveMapPage.tsx`
- Import and call `usePositionMonitor()` at top of component
- Helps developers spot WS gaps during testing

**✓ Checkpoint 3:** Console shows real-time position coverage stats

---

### Phase 4: Emergency Polling for Stale-Online Paradox

**Goal:** Vehicles with `online` status + stale position → aggressive polling

**T006** Create `useEmergencyPositionRefresh()` hook
- File: `src/hooks/useEmergencyPositionRefresh.ts`
- Input: `VehicleWithPosition[]` from `useVehiclesWithPositions()`
- Filter: `device.status === 'online' && isStale === true`
- Action: Call `traccarService.getPositionsByDeviceIds()` every 10s for those IDs
- Merge results into React Query cache via `setQueryData()`

**T007** Integrate into `LiveMapPage.tsx`
- Call `useEmergencyPositionRefresh(vehicles)` after `useVehiclesWithPositions()`
- This runs ONLY for paradox vehicles (online but stale)
- Normal vehicles unaffected (stay at 30s interval)

**✓ Checkpoint 4:** Stale-online vehicles refresh position every 10s

---

### Phase 5: WebSocket Position Push Verification

**Goal:** Confirm Traccar WebSocket actually sends position updates for cache-missing devices

**Investigation Tasks:**

**T008** Add WebSocket message logging
- In `useTraccarWebSocket.ts`, add dev-mode logging:
  ```typescript
  if (import.meta.env.DEV) {
    console.log('[WS positions]', msg.positions?.map(p => p.deviceId));
    console.log('[WS devices]', msg.devices?.map(d => d.id));
  }
  ```
- This shows which devices Traccar is actually streaming

**T009** Document WS behavior in memory
- File: `.claude/memory/traccar-websocket-position-gap.md`
- Document: "Traccar WebSocket only streams positions for devices in in-memory cache"
- Explain: Devices that connected before Traccar restart → not in cache → no WS updates
- Solution: Fallback queries + emergency polling for online-but-stale devices

**✓ Checkpoint 5:** WS behavior documented, workaround implemented

---

### Phase 6: Customer Scenario Test

**Goal:** Reproduce customer's exact scenario and verify fix

**Test Case:**
1. Start with vehicle showing old position (parked at company)
2. Vehicle starts moving (send GPS packets via simulator or real device)
3. Verify:
   - Status badge updates to "Moving" ✅ (already works via device WS)
   - Position updates within 30 seconds ✅ (must work after fix)
   - Speed shows correctly ✅ (from livePos via fallback)
   - Coordinates move on map ✅ (from fallback position)

**T010** Create test plan document
- File: `.toh/gps-position-update-test.md`
- Steps to reproduce customer scenario
- Expected results
- Actual results (filled in during manual test)

**T011** Manual test on dev server
- Run `npm run dev`
- Open LiveMapPage
- Simulate moving vehicle (or use real GPS device)
- Verify position updates < 30s
- Document results in test plan

**✓ Checkpoint 6:** Customer scenario passes, positions update in real-time

---

### Phase 7: Build & Deploy

**T012** Build verification
- Run `npm run build` → 0 TypeScript errors
- Run `npm run lint` → no new warnings
- Run `npm test` → all tests pass

**T013** Memory update
- Update `.claude/memory/active.md` with fix summary
- Update `changelog.md` with detailed fix notes
- Create `traccar-websocket-position-gap.md` in memory
- Link to `[[traccar-positions-cache-gap]]`

**T014** Commit & push
- Commit message: "fix(gps): real-time position updates for cache-missing devices"
- Body: Root cause + 3-part solution (WS fallback trigger + emergency polling + diagnostics)
- Push to main
- Verify CI green

**✓ Checkpoint 7:** Build deployed, memory updated, CI green

---

## 📝 Technical Notes

### Root Cause Deep Dive

**Traccar WebSocket Behavior:**
1. Traccar maintains in-memory "latest position" cache per device
2. When GPS device sends packet → updates PostgreSQL + in-memory cache
3. WebSocket broadcasts `positions` message with updated devices
4. **BUT:** Only devices in cache get broadcast

**Cache Population:**
- Device connects via TCP → added to cache
- Traccar restarts → cache empty
- Devices that connected before restart → NOT in cache
- Future GPS packets from those devices → stored in DB but NOT cached → NO WS broadcast

**Why Customer Saw This:**
- Vehicle was in cache (working normally)
- Traccar restarted (deployment, crash, etc.)
- Cache cleared
- Vehicle NOT in cache anymore
- GPS packets → DB ✅, Cache ❌, WebSocket ❌
- Frontend: Device WS updates (status badge) ✅, Position WS updates ❌
- Result: Status says "Moving" but position frozen

### Solution Architecture

**3-Layer Defense:**

1. **WebSocket Fallback Trigger** (T002)
   - Detects device update without matching position
   - Invalidates fallback queries
   - Fallback refetches from PostgreSQL
   - Latency: ~1-2 seconds

2. **Emergency Polling** (T006-T007)
   - Detects paradox: online + stale position
   - Aggressive 10s polling for those devices only
   - Catches vehicles that slip through WS gaps
   - Latency: max 10 seconds

3. **Existing Fallback System** (already implemented)
   - `useFallbackPositions()` → reads positionId from PostgreSQL
   - `useDeviceIdPositions()` → reads by deviceId (second-chance)
   - Triggered by React Query invalidation
   - Latency: 20-30s normally

**Combined:** Vehicle position NEVER stale > 10s even if WS completely fails

### Performance Impact

**Before Fix:**
- 22/214 devices in cache
- 192 devices frozen (no updates until page reload)
- Customer sees stale data

**After Fix:**
- 22/214 in cache → WS real-time (< 1s)
- 192 fallback devices → PostgreSQL polling (10-30s)
- Emergency polling kicks in for online-but-stale (10s max)

**Query Load:**
- WS working normally: 0 extra queries (cache handles it)
- WS gap detected: 1 query per gap device per 10s
- Worst case: 192 devices × 1 query/10s = 19 queries/sec
- Traccar handles this easily (tested at 667 TPS)

---

## 🎯 Success Metrics

**Fix Verified When:**
- [ ] Customer scenario reproduces: vehicle moves → position updates < 30s
- [ ] Console diagnostics show: "0 online devices with stale positions"
- [ ] Manual test: Force WS disconnect → positions still update via fallback
- [ ] No performance degradation: page load time unchanged
- [ ] Build passes with 0 errors

**Customer Satisfaction:**
- [ ] Customer confirms: "GPS now moves with vehicles in real-time"
- [ ] No false alarms: offline vehicles stay offline (not flickering)
- [ ] Position accuracy: coordinates match actual vehicle location

---

**Estimated Time:** 2-3 hours (investigation + implementation + testing)  
**Risk:** Medium (touches real-time data flow, must not break existing fallback)  
**Impact:** High (customer safety-critical issue)
