# Plan — LiveMap Popup Fix + Reports Coordinates
**Status:** approved
**Created:** 2026-08-10
**Scope:** bellerox-gps-web

---

## Goal
1. **LiveMap popup** — ย้าย SelectedVehiclePanel เป็น `position:fixed` ติดขวา FloatingVehiclePanel จริงๆ + แสดงที่อยู่เป็น ต./อ./จ. ภาษาไทย เหมือน VehicleCard
2. **Reports lat/lng** — เพิ่มคอลัมน์ ละติจูด/ลองติจูด ใน DailyTripReport, DailyAlertsReport (ย้อนหลัง), MonthlySummaryReport

---

## Stack
- React 18 + TypeScript strict
- `useReverseGeocode` hook (มีอยู่แล้ว — `src/hooks/useReverseGeocode.ts`)
- ReportsTable + useDailyTripReport / useDailyAlertsReport hooks
- Traccar trips/events API (`startLat/startLon/endLat/endLon` อยู่ใน response แล้ว)

---

## Root Cause Analysis

### Popup position issue
- `FloatingVehiclePanel`: `position:fixed, left:72, width:360` → right edge = 432px
- `SelectedVehiclePanel`: `position:absolute, left:344` — absolute ภายใน map container ไม่ตรงกับ fixed panel
- **Fix:** เปลี่ยน popup เป็น `position:fixed, top:76, left:440` (= 72+360+8)

### Address format in popup
- ปัจจุบัน popup แสดง `pos.address` (Traccar raw — มักเป็นอังกฤษหรือว่าง)
- VehicleCard (DraggableVehicleCard) ใช้ `useReverseGeocode` → `result.short` = `ต.xxx อ.xxx จ.xxx`
- **Fix:** เพิ่ม `useReverseGeocode` ใน `SelectedVehiclePanel` แล้ว render `.short`

### Reports lat/lng
- `DailyTripRow` มี `startLocation`/`endLocation` (string) แต่ขาด lat/lng
- `DailyAlertRow` มี `location` (string) แต่ขาด lat/lng
- Traccar `/api/reports/trips` return `startLat, startLon, endLat, endLon` ใน raw response
- **Fix:** expose fields จาก hook → type → columns → export

---

## Done When
- [ ] popup ปรากฏขวาของ FloatingVehiclePanel ตรงๆ ไม่ทับกัน
- [ ] popup แสดง ต./อ./จ. ภาษาไทย (เหมือน VehicleCard)
- [ ] DailyTripReport มีคอลัมน์ ละติจูดต้น ลองติจูดต้น ละติจูดปลาย ลองติจูดปลาย
- [ ] DailyAlertsReport มีคอลัมน์ ละติจูด ลองติจูด
- [ ] MonthlySummaryReport: เพิ่ม "ตำแหน่งล่าสุด" (ต./อ./จ.) per vehicle แทน lat/lng aggregate
- [ ] `npm run build` ผ่าน zero TypeScript errors

---

## Phases

### Phase 1 — Popup Fix [~10 min]

- [x] **T001** `src/pages/LiveMapPage.tsx`
  - SelectedVehiclePanel: `position:'absolute', top:80, left:344`
    → `position:'fixed', top:76, left:440` (= 72+360+8, ขวาของ FloatingVehiclePanel)
  - zIndex คงที่ 45

- [x] **T002** `src/pages/LiveMapPage.tsx` (SelectedVehiclePanel component)
  - `import { useReverseGeocode } from '@/hooks/useReverseGeocode'`
  - เพิ่ม `const geo = useReverseGeocode(pos?.latitude, pos?.longitude)`
  - แทนที่ address section: `geo?.short ?? pos?.address ?? 'ไม่มีข้อมูลที่อยู่'`
  - format ที่ได้: `ต.xxx อ.xxx จ.xxx`

**Checkpoint P1:** popup ติดขวา panel + ที่อยู่ไทย

---

### Phase 2 — Reports lat/lng [~20 min]

- [x] **T003**
- [x] **T004**
- [x] **T005**
- [x] **T006**
- [x] **T007** `src/hooks/useDailyTripReport.ts` + `src/hooks/useDailyAlertsReport.ts`
  - อ่าน queryFn ของทั้ง 2 hooks
  - expose `startLat, startLon, endLat, endLon` ใน DailyTripRow
  - expose `latitude, longitude` ใน DailyAlertRow

- [ ] **T004** `src/components/reports/DailyTripReport.tsx`
  - เพิ่ม fields ใน `DailyTripRow`:
    `startLat?: string; startLng?: string; endLat?: string; endLng?: string;`
  - เพิ่ม 4 columns ท้ายตาราง: ละติจูดต้น / ลองติจูดต้น / ละติจูดปลาย / ลองติจูดปลาย
  - format: 6 decimal places (`.toFixed(6)`)
  - เพิ่มใน exportColumns (Excel/CSV)

- [ ] **T005** `src/components/reports/DailyAlertsReport.tsx`
  - เพิ่ม fields ใน `DailyAlertRow`:
    `latitude?: string; longitude?: string;`
  - เพิ่ม 2 columns: ละติจูด / ลองติจูด
  - เพิ่มใน exportColumns

- [ ] **T006** `src/components/reports/MonthlySummaryReport.tsx`
  - Monthly = aggregate per vehicle ไม่มี per-point lat/lng
  - แทนที่ด้วย: เพิ่มคอลัมน์ "ตำแหน่งล่าสุด" ใช้ current position จาก devices query
  - format: `ต.xxx อ.xxx จ.xxx` (ใช้ useReverseGeocode ถ้า need, หรือ current device position.address)

**Checkpoint P2:** รายงานทุก tab มี coordinate columns พร้อม export

---

### Phase 3 — Build & QC [~5 min]

- [ ] **T007** `cd bellerox-gps-web && npm run build`
  - Quote ผลจริง: `✓ built in Xs — zero TypeScript errors`

---

## Files to Touch
```
bellerox-gps-web/src/pages/LiveMapPage.tsx                       T001, T002
bellerox-gps-web/src/hooks/useDailyTripReport.ts                 T003
bellerox-gps-web/src/hooks/useDailyAlertsReport.ts               T003
bellerox-gps-web/src/components/reports/DailyTripReport.tsx      T004
bellerox-gps-web/src/components/reports/DailyAlertsReport.tsx    T005
bellerox-gps-web/src/components/reports/MonthlySummaryReport.tsx T006
```

**Total:** 6 files · 3 phases · 7 tasks · ประมาณ ~30-35 min
