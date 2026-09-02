# Plan: Fix Geocoding Cold Start 502 Errors

**Status:** draft  
**Created:** 2026-09-02  
**Goal:** แก้ 502 errors จาก Cloudflare Worker cold start โดยปรับ frontend retry logic

---

## 🎯 Goal

แก้ปัญหา geocoding 502 errors ที่เกิดจาก Cloudflare Worker cold start (request แรกหลัง idle) โดยปรับ frontend ให้ retry ฉลาดขึ้น

## 📊 Root Cause Analysis

### Current Behavior (Tested)
```bash
Request 1: HTTP 502 (2.26s) ← cold start
Request 2: HTTP 200 (1.35s) ← warm
Request 3: HTTP 200 (0.05s) ← cache HIT
Request 4: HTTP 200 (0.05s) ← cache HIT
Request 5: HTTP 200 (0.06s) ← cache HIT
```

### Why This Happens
1. **Cloudflare Worker cold start** — worker ไม่ได้ใช้งานนาน → ต้อง boot ใหม่
2. **Cold start delay** — 2-8 วินาที (รวม boot + upstream Longdo/Nominatim)
3. **Frontend เปิดแผนที่** — ยิง 30+ geocode requests พร้อมกัน
4. **Retry logic ไม่พอ** — MAX_RETRIES=3, backoff สั้น (1s, 2.5s, 5s)
5. **Frontend ยอมแพ้เร็ว** — timeout 15s แต่ cold start อาจใช้ 20s

### Why Not Fix Worker?
- ✅ Worker code ถูกต้อง (มี Longdo + Nominatim fallback + KV cache)
- ✅ Warm worker = 0.05-1.35s (เร็วมาก)
- ❌ Cold start = Cloudflare limitation (ไม่สามารถ keep-alive ได้ฟรี)
- 🎯 แก้ frontend retry = ถูกกว่า + เร็วกว่า

---

## 📋 Phases

### Phase 1 — Frontend Retry Strategy

**Checkpoint:** Frontend ทน cold start ได้ (retry สำเร็จ)

- [x] **T001** dev-builder — แก้ `useReverseGeocode.ts` retry logic
  - File: `bellerox-gps-web/src/hooks/useReverseGeocode.ts`
  - เพิ่ม MAX_RETRIES: 3 → 5
  - เพิ่ม timeout attempt 1: 15s → 25s (cold start)
  - เพิ่ม timeout attempt 2+: 15s → 12s (warm)
  - เพิ่ม backoff: [2000, 4000, 8000, 15000] (จาก [1000, 2500, 5000])
  - เพิ่ม jitter: 0-500ms (จาก 0-300ms)
  - ห้าม retry 4xx (client error)
  - Retry เฉพาะ 502/503/504/timeout

- [x] **T002** dev-builder — ปรับ concurrency limit
  - File: `bellerox-gps-web/src/hooks/useReverseGeocode.ts`
  - เพิ่ม MAX_CONCURRENT: 3 → 5 (cold start ทนได้มากขึ้น)
  - เพิ่ม comment: "Reduced from 10 to respect Nominatim rate limit + cold start"

- [x] **T003** dev-builder — เพิ่ม cold start hint
  - File: `bellerox-gps-web/src/hooks/useReverseGeocode.ts`
  - อ่าน response header `x-cache` (HIT/MISS)
  - ถ้า MISS + slow response → อาจเป็น cold start
  - Console.log (dev mode) เพื่อ debug

### Phase 2 — Verify Fix

**Checkpoint:** Browser console ไม่เห็น 502 errors, ที่อยู่แสดงครบ

- [x] **T004** test-runner — Clear cache + hard reload test
  - เปิด DevTools Network tab
  - Clear cache + Ctrl+Shift+R
  - สังเกต: geocode requests ไม่ควรมี 502 (retry จะช่วย)
  - สังเกต: request 1 ช้า (2-8s), request 2+ เร็ว (< 1s)

- [x] **T005** test-runner — Verify addresses แสดงครบ
  - รอ 30 วินาที หลังโหลดแผนที่
  - ตรวจว่า FloatingVehiclePanel แสดง "ต./อ./จ." ไม่ใช่พิกัด
  - ตรวจว่าไม่มี "(กำลังรอแปลงพิกัด)" ค้างนาน > 30s

- [x] **T006** test-runner — Build + TypeScript check
  - Run: `cd bellerox-gps-web && npm run build`
  - Expected: ✓ built in ~30s (no TS errors)
  - Run: `npm run lint`
  - Expected: no warnings

---

## ✅ Done When

1. ✅ Browser console ไม่มี 502 errors (หรือมีแค่ 1-2 ครั้งแล้ว retry สำเร็จ)
2. ✅ Geocoding addresses แสดงครบทุกรถภายใน 30 วินาที
3. ✅ Cold start ไม่ทำให้ frontend fail (retry จนสำเร็จ)
4. ✅ `npm run build` ผ่าน (zero TypeScript errors)
5. ✅ DevTools Network tab: เห็น retry behavior (request ซ้ำ 2-3 ครั้งก่อนสำเร็จ)

---

## 📝 Technical Details

### Retry Strategy Comparison

**Before (current):**
```typescript
MAX_RETRIES = 3
BACKOFF = [1000, 2500, 5000]
TIMEOUT = 15_000
Total max wait = 15s + 1s + 15s + 2.5s + 15s + 5s = ~53s
Problem: Cold start 25s > 15s timeout → fail ทุกครั้ง
```

**After (new):**
```typescript
MAX_RETRIES = 5
BACKOFF = [2000, 4000, 8000, 15000]
TIMEOUT = 25s (attempt 1), 12s (attempt 2+)
Total max wait = 25s + 2s + 12s + 4s + 12s + 8s + 12s + 15s = ~90s
Benefit: Cold start 25s < 25s timeout → ทันใน attempt 1 หรือ 2
```

### Why These Numbers?

- **25s timeout (attempt 1):** Cold start worst case = 20s (มี margin 5s)
- **12s timeout (attempt 2+):** Warm worker = 0.05-2s (มี margin 10s)
- **Backoff exponential:** 2s → 4s → 8s → 15s (ไม่เร็วเกินไป ให้ worker ฟื้น)
- **MAX_RETRIES = 5:** รองรับ cold start + transient error (503/504)

### Impact

**Pros:**
- ✅ แก้ปัญหา cold start 502 ได้
- ✅ ไม่ต้องแก้ Worker code
- ✅ ไม่ต้อง Node v22 / wrangler secret
- ✅ ใช้เวลา < 15 นาที

**Cons:**
- ⚠️ Frontend รอนานขึ้น (worst case 90s แทน 53s)
- ⚠️ User เห็น "(กำลังรอแปลงพิกัด)" นาน 10-20s ใน cold start
- ✅ Trade-off: รอนานแต่ได้ address ครบทุกรถ (ดีกว่า 502 error)

---

## 🚀 Execution Notes

**Agent routing:**
- T001-T003: `dev-builder` (แก้ logic + retry)
- T004-T006: `test-runner` (verify + build)

**Files changed:**
- `bellerox-gps-web/src/hooks/useReverseGeocode.ts` (1 file เท่านั้น)

**Estimated time:** 10-15 นาที (1 ไฟล์, logic เดิมมีอยู่แล้ว แค่ปรับตัวเลข)

---

## Status: approved
