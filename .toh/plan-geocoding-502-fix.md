# Plan: Fix Geocoding 502 Errors (Root Cause Analysis)

**Status:** approved  
**Created:** 2026-09-02  
**Goal:** ตรวจสอบสาเหตุที่แท้จริงของ geocoding 502 errors ที่ยังเกิดต่อเนื่องหลัง commit 57035ef และแก้ไขให้เรียบร้อย

---

## 🎯 Goal

แก้ไข geocoding 502 errors ที่เกิดจาก Cloudflare Worker ที่ return `{"error":"geocode unavailable"}` อย่างต่อเนื่อง 100% ของ requests

## 📊 Current State Analysis

### Symptoms
- ✅ Browser logs: ร้อยละ 100 ของ `/geocode` requests ได้ 502 Bad Gateway
- ✅ Response body: `{"error":"geocode unavailable"}` (not empty 502)
- ✅ Response headers: `x-cache: MISS` (ไม่ได้มาจาก KV cache)
- ✅ Test จาก server: 5/5 requests ได้ error เหมือนกัน (ไม่ใช่ browser-specific)

### Root Cause Investigation

**Finding 1: Nominatim ทำงานปกติ**
```bash
curl nominatim → {"address": {"quarter": "แขวงบางชัน", "city": "กรุงเทพมหานคร", ...}}
# Nominatim API ตอบกลับได้ แต่ไม่มี field "province" → Worker แปลง city เป็น province
```

**Finding 2: Worker Code Logic**
```typescript
// Line 296-297 in html-injector.ts
if (env.LONGDO_API_KEY) result = await fetchLongdo(lat, lng, env.LONGDO_API_KEY);
if (!result) result = await fetchNominatim(lat, lng);
```

**Finding 3: Worker Config Check**
- ❌ ไม่สามารถเช็ค `wrangler secret list` ได้ (Node v20 แต่ต้องการ v22)
- ⚠️ **Hypothesis**: `LONGDO_API_KEY` ไม่ได้ตั้งค่า หรือหมดอายุ
- ⚠️ **Hypothesis**: Nominatim fallback ล้มเหลวเพราะ rate limit หรือ timeout

**Finding 4: Error Path**
```typescript
// Line 304: Worker returns 502 only when BOTH geocoders fail
if (!result) return reply({ error: 'geocode unavailable' }, 502, 'MISS');
```

**Finding 5: Nominatim Response Structure**
```json
{
  "address": {
    "quarter": "แขวงบางชัน",
    "suburb": "เขตคลองสามวา",
    "city": "กรุงเทพมหานคร",
    "postcode": "10510"
  }
}
```
→ ไม่มี field `province` สำหรับ Bangkok → Worker code line 260 ควรจะใช้ `city` แทน แต่ต้อง verify

## 🔍 Root Cause Hypothesis

**Primary suspect:** Longdo API key ไม่ได้ตั้งค่าใน Worker secret → `env.LONGDO_API_KEY` เป็น `undefined` → ข้าม fetchLongdo() → ไป fetchNominatim() แต่ล้มเหลวด้วยเหตุผลใดเหตุผลหนึ่ง:
1. Nominatim rate limit (1 req/sec, burst requests → 429/503)
2. Worker timeout (8s) สั้นเกินไป
3. User-Agent header ไม่ถูก format
4. Nominatim parsing logic มีบั๊ก (ไม่รองรับ Bangkok address structure)

## 📋 Solution Plan

### Phase 1: Diagnostic (T001-T003)
- [ ] **T001** root-cause-debugger — เพิ่ม debug logging ใน Worker เพื่อดูว่า path ไหนล้มเหลว
  - File: `infrastructure/cloudflare/workers/html-injector.ts`
  - Add: console.log ทุกจุด decision (Longdo skip/fail, Nominatim fail, parsing result)
  - Add: console.error เมื่อเจอ exception
  
- [ ] **T002** root-cause-debugger — Deploy debug version + tail logs
  - Command: `cd infrastructure && npx wrangler deploy -c wrangler-html-injector.toml`
  - Command: `npx wrangler tail -c wrangler-html-injector.toml` (background terminal)
  - Test: `curl https://api.centerlink.co.th/geocode?lat=13.85151&lon=100.68686`
  
- [ ] **T003** root-cause-debugger — อ่าน logs แล้วระบุสาเหตุจริง
  - Expected: เห็นว่า path ไหนล้มเหลว (Longdo skip? Nominatim timeout? Nominatim rate limit? Parsing error?)

**Checkpoint 1:** รู้สาเหตุแน่ชัดว่า Longdo API key หาย หรือ Nominatim ล้มเหลวเพราะอะไร

### Phase 2: Fix Implementation (T004-T006)

**Scenario A: ถ้า Longdo API key หาย**
- [ ] **T004** backend-connector — ตั้งค่า Longdo API key ใหม่
  - Command: `npx wrangler secret put LONGDO_API_KEY -c wrangler-html-injector.toml`
  - Value: จาก https://map.longdo.com/developers (ต้องขอจากพี่โต)

**Scenario B: ถ้า Nominatim rate limit**
- [ ] **T005** dev-builder — เพิ่ม retry logic + backoff ใน fetchNominatim
  - File: `infrastructure/cloudflare/workers/html-injector.ts`
  - Add: 3 retries with 1s/2s/5s backoff
  - Add: เพิ่ม timeout จาก 8s → 15s

**Scenario C: ถ้า Nominatim parsing fail**
- [ ] **T006** dev-builder — แก้ logic ใน fetchNominatim เพื่อรองรับ Bangkok address
  - File: `infrastructure/cloudflare/workers/html-injector.ts`
  - Fix: ถ้าไม่มี `province` ให้ใช้ `city` แทน (กทม. ไม่มี field province)
  - Current code line 260: `const prov = (a.province || '').replace(/^จังหวัด/, '').trim() || a.city || '';`
  - This should work already — need to verify in logs why it returns null

### Phase 3: Deploy + Verify (T007-T008)
- [ ] **T007** dev-builder — Deploy fixed Worker
  - Command: `cd infrastructure && npx wrangler deploy -c wrangler-html-injector.toml`
  - Remove: debug console.logs
  
- [ ] **T008** test-runner — Verify fix works
  - Test: `curl https://api.centerlink.co.th/geocode?lat=13.85151&lon=100.68686`
  - Expected: `{"subdistrict":"...", "district":"...", "province":"...", "short":"..."}`
  - Test: Browser Network tab → 200 OK responses, not 502
  - Test: Vehicle addresses แสดงบนแผนที่

**Checkpoint 2:** 502 errors หายไป, geocoding ทำงานปกติ

---

## ✅ Done When

1. ✅ Geocoding API returns 200 OK with valid Thai address
2. ✅ Browser console ไม่มี 502 errors
3. ✅ Vehicle addresses แสดงบนแผนที่ (ต./อ./จ. format)
4. ✅ Root cause documented ใน memory

---

## 📝 Notes

- Frontend throttling (commit 57035ef) ยังใช้ได้ — มันป้องกัน burst แต่ไม่แก้ Worker ที่ส่ง 502 กลับมา 100%
- จำเป็นต้องมี Node v22+ เพื่อรัน `wrangler secret list` — ถ้าไม่มีให้ข้ามไป deploy debug version ก่อน
- Worker มี KV cache binding อยู่แล้ว → เมื่อแก้แล้ว address จะถูก cache และไม่ต้องเรียก Nominatim อีก

---

**Estimated Time:** 20-30 minutes (ขึ้นกับว่าต้อง upgrade Node หรือไม่)
