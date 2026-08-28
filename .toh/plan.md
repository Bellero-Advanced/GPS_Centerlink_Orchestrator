# 🛠️ DLT Cross-Tab Rate Limit Fix (Restore 9f78faf)

**Status:** draft  
**Created:** 2026-08-26  
**Problem:** 429 Too Many Requests on DLT send when multiple admins open tabs

---

## 🎯 Goal

**ROOT CAUSE FOUND:** 3 admins × 3 tabs = 3 DLT requests/min from same IP → 429

**Solution:** Restore commit `9f78faf` (22 AUG) — cross-tab rate limit guard via localStorage

Fix:
1. **429 rate limit** → multi-tab sending from same IP (3 admins → 3 req/min)
2. **Missing cross-tab guard** → was fixed in 9f78faf, lost in rollback
3. **No 503/position issues** → that's Traccar infra, not touching

## 🏗️ Stack

- **Services:** `dltService.ts`
- **Hooks:** `useDltAutoSend.ts`
- **Tests:** `dltRateLimit.test.ts` (restore from 9f78faf)

## 📄 Pages Affected

- No UI changes (infra fix only)

## ✅ Done When

- [ ] `msUntilNextDltSend()` restored in dltService
- [ ] `LS_DLT_LAST_SEND` localStorage key added
- [ ] Cross-tab guard in `useDltAutoSend` doSend
- [ ] Atomic claim in `sendDltBatch` before POST
- [ ] Tests restored (7 test cases)
- [ ] Build passes (`npm run build`)
- [ ] Memory updated

---

## 📋 Phases

### Phase 1: Restore dltService Cross-Tab Guard

**Goal:** Add localStorage timestamp guard from 9f78faf

- **T001** `dltService.ts` — Add `LS_DLT_LAST_SEND` constant
  - Line ~42: `export const LS_DLT_LAST_SEND = 'bellerox_dlt_last_send';`

- **T002** `dltService.ts` — Add `msUntilNextDltSend()` function
  - Check localStorage for last send timestamp
  - Return ms to wait (0 if > 55s passed)
  - Handle corrupt/missing timestamps

- **T003** `dltService.ts` — Add atomic claim in `sendDltBatch`
  - Before HTTP POST: check + claim slot in one operation
  - If another tab claimed → log skip, don't send
  - Store ISO timestamp after successful send

**✓ Checkpoint 1:** `msUntilNextDltSend()` function compiles

---

### Phase 2: Update useDltAutoSend Hook

**Goal:** Call cross-tab guard before fetching positions

- **T004** `useDltAutoSend.ts:40-100` — Import `msUntilNextDltSend`
  - Add to imports from `dltService`

- **T005** `useDltAutoSend.ts` — Add guard check in `doSend`
  - Before fetching positions: `const waitMs = msUntilNextDltSend()`
  - If `waitMs > 0` → log skip and return early
  - Comment: "Cross-tab guard: another tab may have sent recently"

**✓ Checkpoint 2:** Run `npm run build` → 0 errors

---

### Phase 3: Restore Tests

**Goal:** Add 7 test cases from 9f78faf

- **T006** Create `src/services/__tests__/dltRateLimit.test.ts`
  - Test 1: First send (no timestamp) → 0ms wait
  - Test 2: Sent 10s ago → 45s wait remaining
  - Test 3: Sent 56s ago → 0ms wait (can send)
  - Test 4: Sent 61s ago → 0ms wait
  - Test 5: Future timestamp (clock backwards) → 0ms wait
  - Test 6: Corrupt timestamp → 0ms wait
  - Test 7: Missing localStorage → 0ms wait

**✓ Checkpoint 3:** Run `npm test` → 7 tests pass

---

### Phase 4: Verify & Polish

- **T007** Build verification
  - Run `npm run build` → 0 errors
  - Run `npm run lint` → no new warnings
  - Check TypeScript strict mode

- **T008** Memory update
  - Update `.claude/memory/active.md` with fix summary
  - Update `changelog.md` with 9f78faf restoration note
  - Add to `decisions.md`: "Multi-tab DLT guard via localStorage"

**✓ Checkpoint 4:** All tasks complete, CI green

---

## 📝 Notes

**Root Cause Found:**
- **Problem:** 3 admins open web → 3 tabs × 60s interval = 3 DLT requests/min from same IP
- **DLT Spec:** Max 3 requests/min per source IP (p.10 of DLT spec PDF)
- **Result:** 429 Too Many Requests

**Solution (9f78faf — 22 AUG):**
- Cross-tab guard via `localStorage.bellerox_dlt_last_send`
- Only 1 tab per browser sends (first tab to claim slot)
- Other tabs see timestamp and skip
- **Status:** Lost in rollback 8d62fa7 (24 AUG)

**What to restore:**
1. `msUntilNextDltSend()` — check localStorage for last send
2. Guard in `useDltAutoSend` doSend — skip if another tab sent
3. Atomic claim in `sendDltBatch` — store timestamp after POST
4. 7 test cases — cover gap window, backwards clocks, corrupt data

**Known Limitation:**
- localStorage is per-browser, not per-IP
- Multiple machines behind same IP can still exceed limit
- But fixes the main case: multiple tabs on same machine

**User Request:**
- "ศึกษาเรื่อง infras ของ server ไปหา DLT"
- "ไม่ต้องไปแตะ GPS เข้า Server"
- ✅ This fix is pure DLT infra (localStorage coordination)

---

**Estimated Time:** 30-40 minutes (restore from known commit)  
**Risk:** Very Low (exact code exists in 9f78faf, just restore it)
