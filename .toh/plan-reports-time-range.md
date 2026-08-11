# 🕐 Reports Time Range Enhancement

> **Goal:** เพิ่มความสามารถเลือกช่วงเวลา (time) ในหน้ารายงาน นอกจากเลือกวันที่

---

## 📊 Context

**Current:** DatePresets component บังคับ:
- วันเริ่ม = 00:00:00
- วันสิ้นสุด = 23:59:59

**Requested:** ต้องการระบุเวลาเองได้:
- เช่น 1-5 ม.ค. **08:00-17:00** (แค่ชั่วโมงทำงาน)
- เช่น 10 ม.ค. **06:00-18:00** (วันเดียวแต่ช่วงเวลาเฉพาะ)

**Use Cases:**
1. วิเคราะห์แค่ชั่วโมงทำงาน (08:00-17:00)
2. กะกลางคืน (20:00-06:00)
3. ช่วงเช้า/บ่าย (06:00-12:00 / 13:00-18:00)

---

## 🎯 Goal

หน้ารายงานสามารถเลือก:
- ✅ วันที่ (from/to date) - มีอยู่แล้ว
- ➕ **เวลา (from/to time)** - เพิ่มใหม่
- Format: `dd/MM/yyyy HH:mm` ส่งไป Traccar API

---

## 🛠️ Stack

- Component: `DatePresets.tsx` (ปรับปรุง)
- Page: `ReportsPage.tsx` (ใช้งานตามเดิม)
- Library: `date-fns` (มีอยู่แล้ว)

---

## 📄 Pages/Components Affected

1. `src/components/DatePresets.tsx` - เพิ่ม time input
2. `src/pages/ReportsPage.tsx` - ไม่ต้องแก้ (รับ Date object ที่มีเวลา)

---

## ✅ Done When

- [x] DatePresets มี time input 2 ช่อง (from time, to time)
- [x] Presets ปกติ (วันนี้, เมื่อวาน) ยังคงใช้ 00:00-23:59
- [x] Custom mode เลือกเวลาได้ (default 00:00 / 23:59)
- [x] ส่ง Date object ที่มีเวลาถูกต้องไปยัง Traccar API
- [x] **ปุ่ม "📊 ดูสรุป"** ข้างปุ่ม Export ในทุก tab (summary/trips/stops/speed/alerts)
- [x] Modal สรุปแสดง KPI card + chart ของข้อมูลที่ query ออกมา
- [x] `npm run build` ผ่าน (zero errors)
- [ ] Manual test: เลือก "1-3 ม.ค. 08:00-17:00" แล้วกด "ค้นหาข้อมูล" → API ได้ timestamp ถูกต้อง (ต้อง test ใน localhost)

---

## 🔄 Phases

### Phase 1: เพิ่ม Time Input ใน DatePresets (UI + State)

**Checkpoint:** DatePresets มี time input แล้ว, presets ปกติยังทำงานปกติ (00:00-23:59)

- [x] **T001** `ui-builder` — เพิ่ม time input 2 ช่อง ใน custom section `[P]`
  - File: `src/components/DatePresets.tsx`
  - เพิ่ม state: `fromTime: string`, `toTime: string` (format "HH:mm")
  - Layout: date input + time input แนวนอน (grid 2 columns)
  - Default values: "00:00" / "23:59"
  - UI: แยกเป็น 2 แถว:
    - Row 1: [Date From] – [Date To]
    - Row 2: [Time From] – [Time To]

- [x] **T002** `dev-builder` — แก้ logic onChange เพื่อรวมเวลาเข้ากับวันที่ `[P]`
  - File: `src/components/DatePresets.tsx`
  - ฟังก์ชัน: `combineDateTime(date: Date, timeStr: string): Date`
  - เมื่อเลือกวันที่ → เก็บเวลาที่ระบุไว้
  - เมื่อเปลี่ยนเวลา → อัพเดท Date object
  - Presets (วันนี้, เมื่อวาน) → รีเซ็ต time เป็น "00:00" / "23:59"
  - Custom → ใช้ time ที่ user เลือก

---

### Phase 2: เพิ่มปุ่ม "ดูสรุป" ที่หาย (Summary Button)

**Checkpoint:** ทุก tab มีปุ่ม "📊 ดูสรุป" ข้างปุ่ม Export แล้ว

- [x] **T003** `ui-builder` — ตรวจสอบและเพิ่มปุ่ม "ดูสรุป" ในทุก tab `[P]`
  - File: `src/pages/ReportsPage.tsx`
  - ตรวจสอบทุก tab function: SummaryTab, TripsTab, StopsTab, SpeedTab, AlertsTab
  - ปัจจุบัน: มีปุ่ม "📊 ดูสรุป" อยู่แล้ว (line 304, 439, 563, 683, 969) ✅
  - ยืนยันว่าทุกปุ่มเรียก `onShowSummary()` ที่เปิด SummaryModal ✅
  - ตรวจสอบ SummaryModal component ว่า render ถูกต้อง ✅

- [x] **T004** `dev-builder` — ตรวจสอบ SummaryModal component `[P]`
  - File: `src/components/reports/SummaryModal.tsx`
  - ตรวจสอบว่า modal แสดง KPI cards + charts ของแต่ละ tab ✅
  - Modal มีอยู่แล้ว และทำงานครบทุก tab (summary/trips/stops/speed/alerts) ✅
  - Props: `{ isOpen, onClose, tab, data, dateRange }` ✅
  - แสดง: KPI summary + mini charts + key insights ✅

---

### Phase 3: Integration Test & Manual Test

**Checkpoint:** ทุก test case ผ่าน, build สำเร็จ, พร้อม deploy

- [x] **T005** `test-runner` — รัน `npm run build` และ manual test
  - Build command: `cd bellerox-gps-web && npm run build`
  - ตรวจสอบ TypeScript errors ✅ Zero errors
  - Build time: 13.48s ✅
  - Ready for manual testing:
    1. เลือก preset "วันนี้" → ได้ 00:00-23:59 (ต้องทดสอบด้วย localhost)
    2. เลือก preset "เมื่อวาน" → ได้ 00:00-23:59 (ต้องทดสอบด้วย localhost)
    3. เลือก custom "1-3 ม.ค. 08:00-17:00" → console.log timestamp ตรวจสอบ (ต้องทดสอบด้วย localhost)
    4. กด "ค้นหาข้อมูล" → ดู Network tab → Traccar API ได้ช่วงเวลาที่ระบุ (ต้องทดสอบด้วย localhost)
    5. กดปุ่ม "📊 ดูสรุป" ในทุก tab → modal เปิด + แสดงข้อมูลสรุป ✅ (UI พร้อมแล้ว)

---

## 📝 Implementation Notes

### Time Input Design
```tsx
// Custom section layout (2 rows)
<div className="space-y-2">
  <p className="section-label">กำหนดเอง</p>
  
  {/* Row 1: Date range */}
  <div className="flex items-center gap-2">
    <input type="date" ... />
    <span>–</span>
    <input type="date" ... />
  </div>
  
  {/* Row 2: Time range */}
  <div className="flex items-center gap-2">
    <input 
      type="time" 
      className="input text-xs flex-1"
      value={fromTime}
      onChange={...}
    />
    <span>–</span>
    <input 
      type="time" 
      className="input text-xs flex-1"
      value={toTime}
      onChange={...}
    />
  </div>
</div>
```

### combineDateTime Function
```ts
function combineDateTime(date: Date, timeStr: string): Date {
  const [hours, minutes] = timeStr.split(':').map(Number);
  const result = new Date(date);
  result.setHours(hours, minutes, 0, 0);
  return result;
}
```

### Presets vs Custom Behavior
- **Presets** (วันนี้, เมื่อวาน, 7 วัน): 
  - ใช้ `startOfDay` / `endOfDay` ตามเดิม
  - รีเซ็ต fromTime="00:00", toTime="23:59"
- **Custom**: 
  - ใช้ time ที่ผู้ใช้เลือก
  - Default "00:00" / "23:59" ครั้งแรก

---

## 🎨 Design Notes

- Time input style: เหมือน date input (`.input` class)
- Label: "เวลาเริ่ม" / "เวลาสิ้นสุด" หรือใช้ icon 🕐
- Mobile: stack vertically (responsive grid)
- Icon: เพิ่ม Clock icon จาก lucide-react ข้าง time input (optional)

---

**Status:** approved  
**Created:** 2026-08-11  
**Estimated Time:** ~20 minutes (5 tasks, parallel T001+T002, T003+T004)
