# 🎯 Plan: POI System + Reports Enhancement

**Created:** 2026-08-14  
**Status:** completed  
**Estimated time:** ~90 minutes  
**Started:** 2026-08-14
**Completed:** 2026-08-14  

---

## Goal

ปรับปรุงระบบรายงานและเพิ่มระบบจุดสนใจ (POI) ให้สมบูรณ์:
1. เพิ่มสรุปในการ export รายงาน (PDF/Excel/CSV)
2. สร้างระบบ POI ที่แยกตาม user พร้อมแผนที่โต้ตอบ
3. แสดงรายงานรถที่ผ่าน POI
4. ปรับ default Live Map ซ่อนเส้นทาง

---

## Stack

- **Frontend:** React 18 + TypeScript + Leaflet
- **Backend:** Traccar 6 (Geofences API)
- **State:** React Query + Zustand
- **Forms:** React Hook Form + Zod

---

## Pages Changed

- `/app/reports` — เพิ่มสรุปใน exports
- `/app/geofences` — เปลี่ยนเป็นหน้า POI เต็มรูปแบบ
- `/app/map` — เพิ่ม POI creation, ซ่อนเส้นทาง default

---

## Definition of Done

- ✅ Reports exports มีสรุปด้านบน (PDF/Excel/CSV)
- ✅ คลิกแผนที่ → popup เพิ่ม POI (รัศมี, ชื่อ, สี)
- ✅ หน้า POI แสดงรถทุกคัน + จุดสนใจของ user
- ✅ POI แยกตาม userId (RLS ใน Traccar)
- ✅ รายงานแสดงรถผ่าน POI ไหนบ้าง
- ✅ Live Map ซ่อนเส้นทางเป็น default
- ✅ Build pass + TypeScript clean

---

## Phase 1: Reports Export Enhancement (4 tasks, ~15 min)

### T001 [P] `ui-builder` — เพิ่มฟังก์ชันสรุปใน export utilities
**Files:**
- `bellerox-gps-web/src/lib/excelExport.ts`
- `bellerox-gps-web/src/services/reportTemplates.ts`

**Action:**
- เพิ่ม summary section ใน `generateTripReportPDF()` (KPI cards ก่อนตาราง)
- เพิ่ม summary rows ใน Excel export (`downloadXLS()`)
- เพิ่ม summary rows ใน CSV export

**Checkpoint T001:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ Export functions include summary parameter
```

---

### T002 [P] `ui-builder` — ส่ง summary data ไปยัง export functions
**Files:**
- `bellerox-gps-web/src/pages/ReportsPage.tsx` (TripsTab, SummaryTab)

**Action:**
- คำนวณ summary stats ใน each tab
- ส่ง summary object ไปยัง `handleExport()` และ `handlePrintPDF()`

**Checkpoint T002:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ Summary calculated in useMemo hooks
```

---

### T003 `dev-builder` — เพิ่ม POI passage tracking ใน reports
**Files:**
- `bellerox-gps-web/src/hooks/useReports.ts`
- `bellerox-gps-web/src/pages/ReportsPage.tsx`

**Action:**
- เพิ่ม `useGeofenceEvents()` hook (query geofenceEnter/Exit events)
- ใน TripsTab: แสดง column "ผ่านจุดสนใจ" (comma-separated POI names)
- Cross-reference trip timestamps กับ geofence events

**Checkpoint T003:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ useGeofenceEvents hook exists
```

---

### T004 `test-runner` — ทดสอบ exports
**Action:**
- เปิด Reports page → เลือกรถ → export PDF/Excel/CSV
- ✅ Summary แสดงด้านบน (ระยะทาง, เวลา, ความเร็ว, trips)
- ✅ ตารางข้อมูลอยู่ใต้สรุป

**Checkpoint T004:**
```bash
# Manual test
# ✅ PDF has summary header
# ✅ Excel has summary rows
# ✅ CSV has summary rows
```

---

## Phase 2: POI Data Model & API (3 tasks, ~20 min)

### T005 `backend-connector` — เพิ่ม userId filter ใน Geofences API
**Files:**
- `bellerox-gps-web/src/services/traccarService.ts`
- `bellerox-gps-web/src/types/traccar.types.ts`

**Action:**
- เพิ่ม `attributes.userId` ใน `TraccarGeofence` type
- แก้ `getGeofences()` ให้ filter by current user
- เพิ่ม `createGeofence()` ให้ auto-set userId จาก session

**Checkpoint T005:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ getGeofences filters by userId
```

---

### T006 `backend-connector` — เพิ่ม POI metadata fields
**Files:**
- `bellerox-gps-web/src/types/traccar.types.ts`

**Action:**
- เพิ่ม type `POIAttributes`:
  ```ts
  interface POIAttributes {
    userId: number;
    color: string;        // hex color
    radius: number;       // meters
    category?: 'warehouse' | 'customer' | 'depot' | 'custom';
  }
  ```
- Extend `TraccarGeofence.attributes` ให้รองรับ POI fields

**Checkpoint T006:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ POIAttributes type exists
```

---

### T007 `dev-builder` — Create POI hooks
**Files:**
- `bellerox-gps-web/src/hooks/usePOI.ts` (new)

**Action:**
- `usePOIs()` — query geofences filtered by userId
- `useCreatePOI()` — mutation ที่ auto-set userId + format WKT
- `useDeletePOI()` — mutation delete geofence
- Convert radius+center → WKT CIRCLE format

**Checkpoint T007:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ usePOI.ts exports 3 hooks
```

---

## Phase 3: POI Map UI (5 tasks, ~35 min)

### T008 `ui-builder` — สร้างหน้า POI page
**Files:**
- `bellerox-gps-web/src/pages/GeofencesPage.tsx` (rename/refactor)
- `bellerox-gps-web/src/components/poi/POIList.tsx` (new)

**Action:**
- แสดง Leaflet map (fullscreen)
- แสดงรถทุกคัน (VehicleMarkers)
- แสดง POI circles ที่มีชื่อ (L.Circle + L.Marker label)
- Sidebar: POI list (ชื่อ, สี, จำนวนรถในรัศมี)

**Checkpoint T008:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ GeofencesPage shows map + vehicles + POI circles
```

---

### T009 [P] `ui-builder` — POI creation popup
**Files:**
- `bellerox-gps-web/src/components/poi/CreatePOIModal.tsx` (new)

**Action:**
- Form: ชื่อ (text), รัศมี (number, default 200m), สี (color picker)
- Leaflet map event: click → show modal with clicked lat/lng
- Submit → call `useCreatePOI()` mutation
- Preview circle บนแผนที่ขณะปรับรัศมี

**Checkpoint T009:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ CreatePOIModal component exists
```

---

### T010 `ui-builder` — Integrate CreatePOIModal with map click
**Files:**
- `bellerox-gps-web/src/pages/GeofencesPage.tsx`

**Action:**
- Leaflet map `onClick` → open `CreatePOIModal` with coordinates
- Show temporary circle preview while modal open
- On submit → create POI → refresh map

**Checkpoint T010:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ Click map → modal appears
```

---

### T011 `ui-builder` — แสดงชื่อ POI บนแผนที่
**Files:**
- `bellerox-gps-web/src/components/map/POILayer.tsx` (new)

**Action:**
- Render L.Circle สำหรับแต่ละ POI
- Render L.Marker (DivIcon) ที่ center ของ circle แสดงชื่อ
- Style: ชื่อขาวพื้นหลังสี POI, border radius, shadow

**Checkpoint T011:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ POI names visible on map
```

---

### T012 `ui-builder` — POI detail sidebar
**Files:**
- `bellerox-gps-web/src/components/poi/POICard.tsx` (new)

**Action:**
- Card แสดง: ชื่อ, สี (dot), รัศมี, จำนวนรถในรัศมี
- Actions: Edit, Delete
- Click card → fly to POI on map

**Checkpoint T012:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ POICard component displays POI info
```

---

## Phase 4: Live Map POI Integration (3 tasks, ~15 min)

### T013 `ui-builder` — เพิ่ม POI creation ใน LiveMapPage
**Files:**
- `bellerox-gps-web/src/pages/LiveMapPage.tsx`

**Action:**
- Import `CreatePOIModal`
- เพิ่ม state `[poiModalOpen, setPoiModalOpen]`
- Map click (when not clicking vehicle) → open POI modal
- Guard: only admin users can create POI from Live Map

**Checkpoint T013:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ Click empty map area → POI modal opens
```

---

### T014 `ui-builder` — แสดง POI overlay ใน LiveMapPage
**Files:**
- `bellerox-gps-web/src/pages/LiveMapPage.tsx`

**Action:**
- Import `POILayer` component
- Render `<POILayer visible={showGeofences} />` (reuse geofences toggle)
- POI circles + names visible when geofences toggle ON

**Checkpoint T014:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ POI overlay renders on Live Map
```

---

### T015 `ui-builder` — ซ่อนเส้นทาง (route trail) เป็น default
**Files:**
- `bellerox-gps-web/src/pages/LiveMapPage.tsx`

**Action:**
- เปลี่ยน `useState(true)` → `useState(false)` สำหรับ `showTrail`
- Default: เส้นทางซ่อนอยู่, user toggle ปุ่มเพื่อแสดง

**Checkpoint T015:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ showTrail default = false
```

---

## Phase 5: POI in Reports (2 tasks, ~10 min)

### T016 `dev-builder` — Query geofence events per trip
**Files:**
- `bellerox-gps-web/src/hooks/useReports.ts`

**Action:**
- `useGeofencePassage(deviceId, from, to)` hook
- Returns: `{ tripId: string, poiNames: string[] }[]`
- Join geofenceEnter events กับ trip timestamps

**Checkpoint T016:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ useGeofencePassage hook exists
```

---

### T017 `ui-builder` — แสดง POI passage column ใน Trips report
**Files:**
- `bellerox-gps-web/src/pages/ReportsPage.tsx` (TripsTab)

**Action:**
- เพิ่ม column "ผ่านจุดสนใจ"
- แสดง comma-separated POI names
- ถ้าไม่ผ่าน POI ไหน แสดง "—"

**Checkpoint T017:**
```bash
npm run build
# ✅ TypeScript clean
# ✅ Trips table shows POI column
```

---

## Phase 6: Testing & Polish (2 tasks, ~5 min)

### T018 `test-runner` — ทดสอบ POI workflow
**Action:**
1. Login as user A → สร้าง POI "คลังสินค้า A"
2. Login as user B → ไม่เห็น POI ของ user A ✅
3. Click Live Map → สร้าง POI ใหม่ ✅
4. ดูรายงาน → รถผ่าน POI แสดงใน column ✅
5. Export PDF → มีสรุปด้านบน ✅

**Checkpoint T018:**
```bash
# Manual test
# ✅ POI user isolation works
# ✅ POI creation from map works
# ✅ Reports show POI passage
```

---

### T019 `test-runner` — Final build verification
**Action:**
```bash
cd bellerox-gps-web
npm run build
npm run lint
```

**Checkpoint T019:**
```bash
# ✅ TypeScript 0 errors
# ✅ ESLint 0 errors
# ✅ Build exits 0
```

---

## Summary

| Phase | Tasks | Time |
|-------|-------|------|
| Phase 1: Reports Enhancement | 4 | 15 min |
| Phase 2: POI Data Model | 3 | 20 min |
| Phase 3: POI Map UI | 5 | 35 min |
| Phase 4: Live Map Integration | 3 | 15 min |
| Phase 5: POI in Reports | 2 | 10 min |
| Phase 6: Testing | 2 | 5 min |
| **Total** | **19 tasks** | **~90 min** |

**Parallel opportunities:** T001, T002 (reports) can run parallel to T005, T006 (backend)

---

**Next:** พี่โต review แผนนี้ แล้วพิมพ์ "Go" เพื่อเริ่มสร้างทั้งแผนอัตโนมัติ!
