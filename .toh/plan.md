# Plan — Reports: Thai Address (ต./อ./จ.) in Location Columns
**Status:** draft
**Created:** 2026-08-10
**Scope:** bellerox-gps-web

---

## Goal
4 คอลัมน์ในหน้ารายงานการเดินทางรายวัน (DailyTripReport) ให้แสดงที่อยู่ไทย ต./อ./จ.
เหมือน VehicleCard ใน FloatingVehiclePanel:
- **สถานที่เริ่มต้น** (startLocation)
- **สถานที่สิ้นสุด** (endLocation)
- **ชื่อสถานที่เริ่มต้น** (startPOI)
- **ชื่อสถานที่สิ้นสุด** (endPOI)

---

## Done When
- [ ] คอลัมน์ startLocation แสดง ต.xxx อ.xxx จ.xxx (จาก startLat/startLng ผ่าน Nominatim)
- [ ] คอลัมน์ endLocation แสดง ต.xxx อ.xxx จ.xxx (จาก endLat/endLng)
- [ ] คอลัมน์ startPOI แสดง ต.xxx อ.xxx จ.xxx (เหมือนกัน — ทดแทน '-')
- [ ] คอลัมน์ endPOI แสดง ต.xxx อ.xxx จ.xxx (เหมือนกัน — ทดแทน '-')
- [ ] ขณะโหลด → แสดงพิกัด lat/lng เป็น fallback (เหมือน popup ใน LiveMap)
- [ ] ใช้ cache ร่วมกับ useReverseGeocode (ไม่ duplicate requests)
- [ ] `npm run build` ผ่าน zero errors

---

## Phase 1 — Add GeoAddressCell + wire columns [~10 min]

- [ ] **T001** `bellerox-gps-web/src/components/reports/DailyTripReport.tsx`
  - เพิ่ม `GeoAddressCell` component (ใช้ `useReverseGeocode` hook)
    - รับ `lat?: string`, `lng?: string`, `fallback?: string`
    - ขณะโหลด: แสดง fallback (lat,lng) หรือ `—`
    - เมื่อได้ result: แสดง `geo.short` (ต.xxx อ.xxx จ.xxx)
  - อัพเดท column render สำหรับ 4 คอลัมน์:
    - `startLocation` → `<GeoAddressCell lat={row.startLat} lng={row.startLng} fallback={value} />`
    - `endLocation`   → `<GeoAddressCell lat={row.endLat}   lng={row.endLng}   fallback={value} />`
    - `startPOI`      → `<GeoAddressCell lat={row.startLat} lng={row.startLng} />`
    - `endPOI`        → `<GeoAddressCell lat={row.endLat}   lng={row.endLng}   />`

**Checkpoint:** `npm run build` — ต้อง exit 0 + quote build time

---

## Files to Touch
```
bellerox-gps-web/src/components/reports/DailyTripReport.tsx   T001
```

**Note:** `ReportsTableColumn.render` รับ `(value, row)` อยู่แล้ว (ReportsTable.tsx:11) — ไม่ต้องแก้ table
**Note:** Export (PDF/Excel/CSV) จะยังใช้ raw Traccar address (trip.startAddress) ตามเดิม — acceptable

**Total:** 1 file · 1 phase · 1 task · ประมาณ ~10 min
