# 🎯 Plan: Bug Fixes — Reports + POI

**Created:** 2026-08-18  
**Status:** approved  
**Estimated time:** ~45 minutes  

---

## Goal

แก้ไขบั๊กและปรับปรุงฟีเจอร์ที่ยังไม่สมบูรณ์:
1. แก้ระยะทางติดลบในรายงาน
2. แก้หน้า POI ให้แสดงรถและคลิกเพิ่ม POI ได้
3. เพิ่มสรุปใน PDF Export
4. แสดง address ใน Export (CSV/Excel)
5. อนุญาตให้ user ทั่วไปเพิ่ม POI ได้ (ไม่ใช่แค่ admin)
6. Deploy งานใหม่

---

## Stack

- **Frontend:** React 18 + TypeScript + Leaflet
- **Backend:** Traccar 6
- **State:** React Query + Zustand

---

## Pages Changed

- `/app/reports` — แก้ระยะทางติดลบ + PDF summary + address ใน export
- `/app/geofences` — แก้ POI map + vehicle markers + user permissions

---

## Definition of Done

- ✅ ระยะทางไม่มีค่าติดลบ (ใช้ Math.abs())
- ✅ หน้า POI แสดงรถทุกคัน
- ✅ คลิกแมพ → สร้าง POI ได้ (ทุก user)
- ✅ PDF มี summary KPI ด้านบน
- ✅ Export CSV/Excel แสดง address column
- ✅ User ทั่วไปเพิ่ม POI ได้
- ✅ Push to production
- ✅ Build pass + TypeScript clean

---

## Phase 1: Fix Negative Distance Bug (2 tasks, ~10 min)

### T001 `dev-builder` — เพิ่ม Math.abs() ใน distance calculations
**Files:**
- `bellerox-gps-web/src/lib/units.ts`
- `bellerox-gps-web/src/pages/ReportsPage.tsx`

**Action:**
- แก้ `metersToKm()` และ `formatDistance()` ให้ใช้ `Math.abs(meters)`
- ตรวจสอบทุกที่ที่แสดงระยะทาง — ป้องกันค่าติดลบ
- แก้ export functions ให้ใช้ Math.abs() ด้วย

**Checkpoint T001:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ metersToKm uses Math.abs()
```

---

### T002 `test-runner` — ทดสอบระยะทาง
**Action:**
- เปิดหน้ารายงาน → ตรวจสอบคอลัมน์ระยะทาง
- ✅ ไม่มีค่าติดลบ

**Checkpoint T002:**
```bash
# Manual test
# ✅ Distance columns show positive values only
```

---

## Phase 2: Fix POI Page (3 tasks, ~15 min)

### T003 `ui-builder` — แสดง vehicle markers ในหน้า POI
**Files:**
- `bellerox-gps-web/src/pages/GeofencesPage.tsx`

**Action:**
- Import `useVehiclesWithPositions` hook
- Render `VehicleMarker` components บนแผนที่
- แสดงรถทุกคันพร้อมตำแหน่งปัจจุบัน

**Checkpoint T003:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ Vehicle markers rendered on POI page
```

---

### T004 `ui-builder` — แก้ map click handler ให้เพิ่ม POI ได้
**Files:**
- `bellerox-gps-web/src/pages/GeofencesPage.tsx`

**Action:**
- เพิ่ม Leaflet map `onClick` event
- เปิด CreatePOIModal พร้อมพิกัดที่คลิก
- ตรวจสอบว่า modal component ถูก import และ render

**Checkpoint T004:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ Map onClick handler exists
```

---

### T005 `dev-builder` — อนุญาตให้ user ทั่วไปเพิ่ม POI
**Files:**
- `bellerox-gps-web/src/pages/GeofencesPage.tsx`
- `bellerox-gps-web/src/pages/LiveMapPage.tsx`

**Action:**
- ลบ `if (user.administrator)` guard ออก
- ทุก user สามารถเพิ่ม POI ได้
- POI จะ filter by userId อยู่แล้ว (RLS ใน Traccar)

**Checkpoint T005:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ No admin-only guards for POI creation
```

---

## Phase 3: Fix PDF Export Summary (2 tasks, ~10 min)

### T006 `ui-builder` — เพิ่ม summary ใน PDF templates
**Files:**
- `bellerox-gps-web/src/services/reportTemplates.ts`

**Action:**
- แก้ `generateTripReportPDF()` ให้แสดง summary KPI cards ด้านบน
- แสดง: จำนวน trips, ระยะทางรวม, เวลารวม, ความเร็วสูงสุด
- Format เป็น HTML table พร้อม style

**Checkpoint T006:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ PDF templates include summary section
```

---

### T007 `test-runner` — ทดสอบ PDF export
**Action:**
- เปิดหน้ารายงาน → กด PDF
- ✅ มี summary section ด้านบน
- ✅ ตารางข้อมูลอยู่ใต้

**Checkpoint T007:**
```bash
# Manual test
# ✅ PDF shows summary KPIs
```

---

## Phase 4: Fix Export Address Column (2 tasks, ~5 min)

### T008 `dev-builder` — แสดง address ใน CSV/Excel export
**Files:**
- `bellerox-gps-web/src/pages/ReportsPage.tsx`

**Action:**
- ตรวจสอบ export functions (`handleExport` ใน TripsTab)
- ตรวจสอบว่า `startAddress` และ `endAddress` ถูกส่งไปใน dataRows
- เพิ่มคอลัมน์ "ต้นทาง" และ "ปลายทาง" ใน headers

**Checkpoint T008:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ Export includes address columns
```

---

### T009 `test-runner` — ทดสอบ export
**Action:**
- เปิดหน้ารายงาน → export CSV/Excel
- ✅ คอลัมน์สถานที่แสดงข้อความ (ไม่ว่าง)

**Checkpoint T009:**
```bash
# Manual test
# ✅ Address columns populated in exports
```

---

## Phase 5: Offline Vehicle Alert (2 tasks, ~10 min)

### T010 `ui-builder` — สร้าง OfflineAlertModal component
**Files:**
- `bellerox-gps-web/src/components/alerts/OfflineAlertModal.tsx` (new)

**Action:**
- Modal แสดงรายชื่อพาหนะ offline (status = 'offline')
- Checkbox "ไม่แจ้งเตือนอีกวันนี้" (save to localStorage with date)
- ปุ่ม "ปิด" และ "ดูรายละเอียด"

**Checkpoint T010:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ OfflineAlertModal component exists
```

---

### T011 `ui-builder` — แสดง popup เมื่อเข้าระบบ
**Files:**
- `bellerox-gps-web/src/pages/DashboardPage.tsx` (or Layout.tsx)

**Action:**
- useEffect on mount → check offline vehicles
- ตรวจสอบ localStorage `offlineAlert_dismissed_${today}` → ถ้ายังไม่ dismiss วันนี้ → แสดง modal
- แสดงเฉพาะเมื่อมีพาหนะ offline > 0

**Checkpoint T011:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ Modal shown on first login if vehicles offline
```

---

## Phase 6: Deploy to Production (2 tasks, ~5 min)

### T012 `test-runner` — Final build verification
**Action:**
```bash
cd bellerox-gps-web
npm run build
npm run lint
```

**Checkpoint T010:**
```bash
# ✅ TypeScript 0 errors
# ✅ ESLint 0 errors
# ✅ Build exits 0
```

---

### T013 `dev-builder` — Push to production
**Action:**
```bash
cd bellerox-gps-web
git add .
git commit -m "fix: negative distance + POI bugs + export enhancements + offline alert"
git push origin main
cd ..
git add bellerox-gps-web
git commit -m "chore: update bellerox-gps-web submodule pointer"
git push origin main
```

**Checkpoint T013:**
```bash
# ✅ Changes pushed to origin/main
# ✅ Submodule pointer updated
```

---

## Summary

| Phase | Tasks | Time |
|-------|-------|------|
| Phase 1: Negative Distance Fix | 2 | 10 min |
| Phase 2: POI Page Fixes | 3 | 15 min |
| Phase 3: PDF Summary | 2 | 10 min |
| Phase 4: Export Address | 2 | 5 min |
| Phase 5: Deploy | 2 | 5 min |
| Phase 6: Deploy | 2 | 5 min |
| **Total** | **13 tasks** | **~55 min** |

---

**Next:** พี่โต review แผนนี้ แล้วพิมพ์ "Go" เพื่อเริ่มแก้บั๊กทั้งหมดอัตโนมัติ!
