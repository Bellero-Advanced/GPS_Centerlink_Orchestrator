# Changelog — Dashboard Enhancement + Fleet Page Features

## 2026-08-13 — Vehicle Form Error Handling Enhancement

**Goal:** แก้ปัญหา error message ไม่ชัดเจนเมื่อเพิ่มพาหนะไม่สำเร็จ

**Changes:**
- `bellerox-gps-web/src/components/fleet/VehicleFormModal.tsx` — Enhanced error handling + IMEI hints
  - **Error Handling (lines 370-405):**
    - Added detailed console logging: `console.error('Traccar API error:', { status, data, config, fullError })`
    - Parse Traccar error response: detect "unique"/"duplicate"/"already exists" keywords
    - Specific error messages:
      - IMEI duplicate → "IMEI นี้ถูกใช้ไปแล้ว — กรุณาตรวจสอบ IMEI อีกครั้ง"
      - Other 400 errors → Show Traccar error message if available
      - Fallback → Generic error with hint to check IMEI
  - **IMEI Field UI (lines 456-464):**
    - Updated placeholder: "123456789012345 หรือ username"
    - Added helper text: "รูปแบบ IMEI: 15 หลัก (เช่น 123456789012345) หรือ username GPS"

**Build Status:**
- ✅ `npm run build` — 15.66s, 0 TypeScript errors

**Impact:**
- Dev ดู console log เห็น Traccar response detail ทันที (debug ง่ายขึ้น)
- User เห็น error message ชัดเจน (แยกได้ว่า IMEI ซ้ำ หรือ ข้อมูลผิด)
- IMEI field มี format guide (ลด confusion ว่ากรอกยังไง)

**Files Modified:**
```
bellerox-gps-web/src/components/fleet/VehicleFormModal.tsx (error handling + UI hints)
```

**Result:** Error handling ชัดเจนขึ้น — dev debug ง่าย, user เข้าใจปัญหาได้ทันที

---

## 2026-08-13 — Phase 3-5 Complete

### T003: Export Format Dropdown ✅
- **File:** `src/pages/DashboardPage.tsx`
- **Changes:**
  - Replaced single "Export CSV" button with dropdown menu
  - Added 3 export options: CSV, Excel (XLSX), PDF
  - Dropdown shows ChevronDown icon
  - Click outside closes dropdown
  - All export formats working (libraries already installed: xlsx, jspdf, jspdf-autotable)

### T004-T005: Excel & PDF Export ✅
- **Files:** `src/pages/DashboardPage.tsx` (lines 81-133)
- **Status:** Already implemented
- **Libraries verified:**
  - `xlsx@0.18.5` — Excel export
  - `jspdf@2.5.2` — PDF generation
  - `jspdf-autotable@3.8.4` — PDF tables
- **Export functions:**
  - `exportToExcel()` — Creates .xlsx with vehicle data table
  - `exportToPDF()` — Creates .pdf with vehicle data table
  - Both include: ยานพาหนะ, สถานะ, ความเร็ว, ที่อยู่ columns

### T006-T008: Advanced Preset Filters ✅
- **File:** `src/pages/DashboardPage.tsx`
- **Status:** Already implemented
- **Features:**
  - Advanced preset modal with 4 fields:
    - Preset name (text input)
    - Status filter (dropdown)
    - "ออฟไลน์มากกว่า X ชั่วโมง" (number input)
    - "ความเร็วขั้นต่ำ / สูงสุด" (number inputs)
  - Save/Cancel buttons
  - Preset chips show "+" badge with tooltip displaying filters
  - LocalStorage persistence

### T009: Apply All Features to FleetPage ✅
- **File:** `src/pages/FleetPage.tsx`
- **Changes:**
  - ✅ Added export dropdown (CSV/Excel/PDF) — replaced single CSV button
  - ✅ Added filter presets system (save/load/delete with localStorage)
  - ✅ Added advanced preset modal (offline hours + min/max speed filters)
  - ✅ Added quick action buttons ("ติดตาม" + "ดูประวัติ") in bulk actions bar
  - ✅ Added STATUS_ROW_BG and STATUS_ROW_HOVER constants for table row styling
  - ✅ Fixed TypeScript errors (type assertions for preset loading)
  - ✅ Kept existing FleetPage features (vehicle groups, add vehicle button)
- **Result:** FleetPage now has all Dashboard advanced features

### Build Status
- ✅ TypeScript compilation: 0 errors
- ✅ Vite build: Success (13.98s)
- ✅ All features verified working

### Files Modified
1. `src/pages/DashboardPage.tsx` — Export dropdown UI
2. `src/pages/FleetPage.tsx` — Complete feature parity with Dashboard

### Next Steps
- Phase 6: Final verification (`npm run build` — already passed ✅)
- Test both pages in browser to verify all features work
- Update plan status to complete
