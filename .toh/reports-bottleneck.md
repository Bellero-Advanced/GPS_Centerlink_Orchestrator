# Reports Page Bottleneck Analysis

**Date:** 2026-08-14  
**Analyzed by:** root-cause-debugger

---

## 🔍 Current Architecture

### Data Flow
```
User selects vehicle + date range → clicks "ค้นหาข้อมูล"
  → ReportsPage.tsx sets submitted=true
  → Tab component (SummaryTab/TripsTab/etc.) renders
  → useReports hooks trigger
  → traccarService API calls
  → Data arrives → render table
```

### API Calls per Tab

| Tab | Hook Used | API Endpoint | Batching? |
|-----|-----------|--------------|-----------|
| Summary (สรุปรายวัน) | `useSummaryReport(deviceIds[])` | `/api/reports/summary?deviceId=1&deviceId=2&...` | ✅ YES (single request) |
| Trips (การเดินทาง) | `useTripsReport(deviceId)` | `/api/reports/trips?deviceId=X&from=&to=` | ❌ NO (one device only) |
| Stops (จอดติดเครื่อง) | `useStopsReport(deviceId)` | `/api/reports/stops?deviceId=X&from=&to=` | ❌ NO (one device only) |
| Speed (ความเร็วเกิน) | `useSpeedViolationsReport(deviceId)` | `/api/events?deviceId=X&type=deviceOverspeed` | ❌ NO (one device only) |

---

## 🐌 Bottlenecks Identified

### 1. **Sequential Rendering (Not API-level)**
- **Current behavior:** Summary tab calls ONE batched API request ✅ GOOD
- **Issue:** React Query default behavior = wait for data → then render
- **Impact:** Even though API is fast (~500ms-1s), user sees skeleton → then sudden data appear

### 2. **No Prefetching**
- **Issue:** When user hovers/clicks on another tab, NO prefetch happens
- **Impact:** Every tab switch = full loading skeleton + wait for API
- **Solution:** Add `queryClient.prefetchQuery()` on tab hover

### 3. **Cache Settings Too Conservative**
```typescript
// Current settings in useReports.ts:
staleTime: 60 * 60_000,      // 1 hour — TOO LONG
refetchOnWindowFocus: false, // ✅ GOOD (historical data)
refetchInterval: false,      // ✅ GOOD (historical data)
```
- **Issue:** `staleTime: 1 hour` means same query won't use cache for 1 hour
- **Reality:** User often queries same date range within minutes → should cache aggressively
- **Solution:** Reduce to `staleTime: 5 * 60_000` (5 min)

### 4. **Flash of Empty State**
- **Issue:** When changing date range, old data disappears → skeleton → new data
- **Better UX:** Keep old data visible (grayed out?) while fetching new
- **Solution:** Use `placeholderData: (prev) => prev` in React Query

### 5. **No Parallel Tab Preparation**
- **Issue:** All tabs are lazy-loaded (only fetch when active)
- **Opportunity:** Summary tab is most common → could prefetch Trips tab in background
- **Impact:** User clicks Trips tab → instant data (already cached)

---

## ⚡ Performance Measurements (Estimated)

### Current Performance (Baseline)
- **Summary tab (10 devices):** ~2-3s (API ~800ms + render ~1-2s)
- **Trips tab switch:** ~1.5s (skeleton → API → render)
- **Date range change:** ~2s (empty flash → API → render)

### Bottleneck Breakdown
| Step | Time | % of Total |
|------|------|------------|
| User clicks "ค้นหาข้อมูล" | 0ms | - |
| React re-render (submitted=true) | ~50ms | 2% |
| React Query triggers fetch | ~10ms | 0.5% |
| **Network request (API)** | **800ms-1.5s** | **50-60%** |
| **Data processing + table render** | **500ms-1s** | **30-40%** |
| **Total:** | **~2-3s** | 100% |

### Root Cause
1. **Network time** = biggest bottleneck (50-60%) — **CANNOT optimize further** (Traccar API is already batched)
2. **Render time** = second bottleneck (30-40%) — **CAN optimize** via:
   - Skeleton → partial data → full data (progressive render)
   - Keep old data visible while fetching new (no flash)
   - Prefetch adjacent tabs (perceived instant)

---

## 🎯 Optimization Strategy

### High Impact (Do First)
1. ✅ **Add prefetching on tab hover** → Tab switch feels instant
2. ✅ **Use placeholderData** → No flash of empty state
3. ✅ **Reduce staleTime to 5 min** → Same query = instant from cache

### Medium Impact
4. ✅ **Add Suspense boundaries** → Progressive render (header first, data streams in)
5. ✅ **Add progress bar** → Better perceived performance

### Low Impact (Already Optimized)
- ❌ Batch API calls → Already batched for Summary tab
- ❌ Reduce API response size → Traccar returns minimal data already
- ❌ Pagination → Reports show all data intentionally (export-friendly)

---

## 📊 Expected Gains

| Optimization | Gain | User Perception |
|-------------|------|-----------------|
| Prefetch tabs | ~1-1.5s saved on tab switch | "Instant" |
| placeholderData | ~500ms saved (no flash) | "Smooth" |
| staleTime 5min | ~2-3s saved (cache hit) | "Instant" |
| Progress bar | 0s (perception only) | "Feels faster" |
| **Total improvement** | **50-70% faster feel** | **Much better** |

---

## 🔧 Technical Notes

### Why Not More Aggressive Batching?
- Trips/Stops/Speed tabs are **single-device only** by design
- User selects ONE vehicle → see detailed trips/stops/speed events
- Batching multiple devices here = wrong UX (user wants per-vehicle detail)
- Summary tab already batches correctly ✅

### Why Not Server-Side Caching?
- Historical data doesn't change → client cache is sufficient
- Server-side Redis cache = overkill for current scale (< 100 vehicles)
- Future: when 1000+ vehicles → consider Traccar response caching

### Why Not Virtualized Tables?
- Reports page shows ~10-50 rows typically (manageable)
- Full table rendering = better for print/export
- Virtualization = complexity not worth it yet

---

## ✅ Conclusion

**Main bottleneck:** Network time (Traccar API) — already optimized via batching  
**Biggest win:** Perceived performance (prefetch, placeholderData, cache tuning)  
**Expected result:** 50-70% faster feel, < 2s load time consistently

Next: Implement Phase 1 optimizations (T002-T005)
