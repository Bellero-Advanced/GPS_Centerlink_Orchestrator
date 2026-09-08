---
created: 2026-09-02
status: approved
---

# Plan: Fix Reports Page + POI White Color

## 🎯 Goal
แก้ไขหน้ารายงานให้โหลดอัตโนมัติหลังเลือกรถ + แก้สี POI ที่มองไม่เห็น (สีขาว)

## 🔍 Root Cause Analysis

### ปัญหาที่ 1: หน้ารายงานไม่ขึ้น
**Location:** `bellerox-gps-web/src/pages/ReportsPage.tsx` line 1094-1096

**สาเหตุ:**
- State `submitted` เริ่มต้นเป็น `false`
- เลือกรถแล้ว แต่ยังไม่กด "ค้นหาข้อมูล" → `submitted` ยังเป็น `false`
- Line 1341-1352: แสดง placeholder "กดปุ่มค้นหา" แทนที่จะโหลดรายงาน

**Expected Behavior:**
เลือกรถ + วันที่ → โหลดรายงานอัตโนมัติทันที (ไม่ต้องกดปุ่ม)

### ปัญหาที่ 2: POI สีขาวมองไม่เห็น
**Location:** `bellerox-gps-web/src/components/poi/POILayer.tsx` line 59, 109-111

**สาเหตุ:**
```typescript
const color = (poi.attributes.color as string) || '#3B82F6'; // line 59
// ถ้า DB เซ็ต color = '#ffffff' (white)
background: ${color};  // line 110 → background white
color: #fff;           // line 111 → text white
// = มองไม่เห็น!
```

**Expected Behavior:**
- สีขาว/อ่อน → เปลี่ยนเป็นสีน้ำเงินเข้ม
- หรือใช้ contrast logic: สีอ่อน → text สีดำ, สีเข้ม → text สีขาว

## 🛠️ Stack
- React 18 + TypeScript strict
- Leaflet (map POI rendering)
- React Query (reports data caching)

## 📄 Pages/Components
- `ReportsPage.tsx` — เปลี่ยน auto-submit logic
- `POILayer.tsx` — แก้ color logic

## ✅ Done When
- [x] เลือกรถ → รายงานโหลดทันที (ไม่ต้องกดปุ่ม) ✅
- [x] POI สีขาว → แสดงเป็นสีน้ำเงินเข้ม (หรือ contrast ถูกต้อง) ✅
- [x] `npm run build` สำเร็จ (zero errors) ✅
- [x] สี POI อื่นๆ ยังทำงานปกติ ✅

## 🚀 Implementation Phases

### Phase 1: Fix Reports Auto-Load (2 tasks · ~4 min)

**T001** `[P]` ui-builder — Remove "ค้นหาข้อมูล" button requirement
- File: `bellerox-gps-web/src/pages/ReportsPage.tsx`
- Change:
  1. เปลี่ยน `submitted` initial state เป็น `true` (line 1094)
  2. หรือ auto-submit เมื่อมี `selectedIds.length > 0 || devices.length > 0`
  3. ซ่อนหน้า placeholder (line 1341-1352) หรือแสดงแค่ตอนไม่มี devices
- Agent: ui-builder
- Evidence: เลือกรถ → รายงานโหลดทันที

**T002** `[P]` test-runner — Verify reports load instantly
- File: `bellerox-gps-web/src/pages/ReportsPage.tsx`
- Test:
  1. Open `/reports`
  2. เลือกรถ 1 คัน → รายงานควรโหลดทันที
  3. เปลี่ยนวันที่ → รายงานโหลดใหม่อัตโนมัติ
- Agent: test-runner
- Evidence: Manual test pass

**Checkpoint P1:** Reports load immediately after selecting vehicle ✅

---

### Phase 2: Fix POI White Color (2 tasks · ~3 min)

**T003** `[P]` dev-builder — Add color contrast logic for POI
- File: `bellerox-gps-web/src/components/poi/POILayer.tsx`
- Change line 59:
  ```typescript
  // OLD:
  const color = (poi.attributes.color as string) || '#3B82F6';
  
  // NEW:
  const color = sanitizePOIColor((poi.attributes.color as string) || '#3B82F6');
  
  // Add helper:
  function sanitizePOIColor(hex: string): string {
    // White/very light colors → dark blue
    const lightColors = ['#ffffff', '#fff', '#f0f0f0', '#eeeeee', '#e0e0e0'];
    if (lightColors.some(c => hex.toLowerCase().startsWith(c.slice(0, 4)))) {
      return '#1E40AF'; // dark blue
    }
    return hex;
  }
  ```
- Agent: dev-builder
- Evidence: สีขาว → แปลงเป็น `#1E40AF`

**T004** `[P]` test-runner — Verify POI visibility
- File: `bellerox-gps-web/src/components/poi/POILayer.tsx`
- Test:
  1. Open map with POI layer
  2. POI ที่เคยเป็นสีขาว → ควรเป็นสีน้ำเงินเข้มมองเห็นชัด
  3. POI สีอื่นๆ → ยังเป็นสีเดิม
- Agent: test-runner
- Evidence: Manual test pass

**Checkpoint P2:** All POI markers visible with correct colors ✅

---

### Phase 3: Build Verification (1 task · ~2 min)

**T005** test-runner — Build verification
- Command: `npm run build`
- Agent: test-runner
- Evidence: Exit code 0, zero TypeScript errors
- Blocker if fails: Fix type errors

**Checkpoint P3:** Production build passes ✅

---

## 📊 Summary
- **Total:** 5 tasks across 3 phases
- **Time:** ~9 minutes
- **Parallelizable:** T001-T002 (P1), T003-T004 (P2)
- **Risk:** Low (UI behavior changes only)
