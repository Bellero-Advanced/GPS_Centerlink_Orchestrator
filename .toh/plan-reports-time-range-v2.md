# แผนงาน: เพิ่ม Date/Time Range Picker + ปรับปรุง Summary Modal

**Status:** `draft`  
**Created:** 2025-08-12  
**Goal:** เพิ่ม custom date/time picker ให้ user เลือกช่วงเวลาเองได้ในหน้ารายงานทั้ง 3 tab + ปรับ Summary Modal ให้แสดงข้อมูลครบถ้วนตามที่ user ต้องการ

---

## 🎯 Goal

User สามารถ:
1. **เลือกวันที่**: ตั้งแต่วันไหนถึงวันไหน (custom date range)
2. **เลือกเวลา**: ตั้งแต่เวลาไหนถึงเวลาไหน (custom time range)
3. **ใช้ preset**: ปุ่ม preset (วันนี้/เมื่อวาน/7วัน) ยังใช้งานได้
4. **ดูสรุป**: Summary Modal แสดงข้อมูลครบถ้วน ไม่มี emoji

---

## 📚 Stack

- React 18 + TypeScript (strict)
- date-fns (วันที่/เวลา)
- HTML5 native date/time inputs
- CSS variables (design system)

---

## 📄 Pages Affected

- `src/components/ui/DateTimeRangePicker.tsx` — component ใหม่
- `src/components/reports/DailyTripReport.tsx` — รายงานรายวัน
- `src/components/reports/DailyAlertsReport.tsx` — รายงานย้อนหลัง
- `src/components/reports/MonthlySummaryReport.tsx` — รายงานรายเดือน
- `src/components/reports/SummaryModal.tsx` — Modal สรุปข้อมูล

---

## ✅ Done When

- [ ] มี DateTimeRangePicker component ที่เลือกวันที่ + เวลาได้
- [ ] ทั้ง 3 reports มี custom date/time picker
- [ ] ปุ่ม preset ยังใช้งานได้ปกติ
- [ ] Summary Modal ไม่มี emoji ในหัวข้อ
- [ ] Summary Modal แสดงข้อมูล: รวมเวลาจอดรถ, รวมเวลาเครื่องยนต์ทำงาน, ความเร็วเฉลี่ย, รวมระยะทาง, ใช้น้ำมันทั้งหมด, รวมเวลา PTO เปิด, ค่าน้ำมัน
- [ ] `npm run build` ผ่าน (zero errors)
- [ ] UI responsive และทำงานบน mobile

---

## 📋 Phases

### Phase 1: สร้าง DateTimeRangePicker Component

**Checkpoint:** DateTimeRangePicker component สร้างเสร็จ พร้อมใช้งาน

**T001** ui-builder — สร้าง `DateTimeRangePicker.tsx`  
**File:** `bellerox-gps-web/src/components/ui/DateTimeRangePicker.tsx`  
**Detail:**
- รับ props:
  ```typescript
  interface DateTimeRangePickerProps {
    value: [Date, Date];
    onChange: (range: [Date, Date]) => void;
    disabled?: boolean;
  }
  ```
- UI Layout:
  ```
  [ตั้งแต่วันที่: 📅 input] [เวลา: 🕐 input]
  [ถึงวันที่:   📅 input] [เวลา: 🕐 input]
  ```
- ใช้ HTML5 native inputs:
  - `<input type="date">` สำหรับวันที่
  - `<input type="time">` สำหรับเวลา
- Validation:
  - fromDate ต้องไม่มากกว่า toDate
  - ถ้า fromDate > toDate → swap อัตโนมัติ
- Style ตาม design system:
  - `border: var(--border)`
  - `background: var(--surface-0)`
  - `color: var(--ink-2)`
  - rounded-lg, padding เท่ากับ button อื่นๆ
- Responsive: stack vertically บน mobile (< 640px)

---

### Phase 2: เพิ่ม Custom Date/Time Picker ในหน้ารายงาน

**Checkpoint:** ทั้ง 3 reports มี custom date/time picker ทำงานได้

**T002** dev-builder — เพิ่ม DateTimeRangePicker ใน `DailyTripReport.tsx`  
**File:** `bellerox-gps-web/src/components/reports/DailyTripReport.tsx`  
**Detail:**
- Import `DateTimeRangePicker`
- เพิ่ม UI ใต้ Vehicle selector (บรรทัด ~346-404)
- Layout ใหม่:
  ```tsx
  <div className="flex flex-wrap items-center gap-3">
    {/* Vehicle Selector (มีอยู่แล้ว) */}
    <div className="w-[280px]">
      <SearchSelect ... />
    </div>

    {/* NEW: DateTimeRangePicker */}
    <DateTimeRangePicker
      value={dateRange}
      onChange={setDateRange}
      disabled={loadingDevices}
    />

    {/* Preset Buttons (เก็บไว้) */}
    <div className="flex gap-2 flex-wrap">
      <button onClick={() => setPreset('today')}>วันนี้</button>
      <button onClick={() => setPreset('yesterday')}>เมื่อวาน</button>
      ...
    </div>
  </div>
  ```
- Wire `dateRange` state เข้า `useDailyTripReport()` (มีอยู่แล้ว บรรทัด 95)
- ทดสอบ: เลือกวันที่/เวลา → ตารางอัพเดท

**T003** dev-builder — เพิ่ม DateTimeRangePicker ใน `DailyAlertsReport.tsx`  
**File:** `bellerox-gps-web/src/components/reports/DailyAlertsReport.tsx`  
**Detail:** 
- เหมือน T002 เป็นด้าน
- หา filter section ของ DailyAlertsReport
- เพิ่ม DateTimeRangePicker
- เก็บ preset buttons
- Wire เข้า `useDailyAlertsReport()` hook

**T004** dev-builder — เพิ่ม DateTimeRangePicker ใน `MonthlySummaryReport.tsx`  
**File:** `bellerox-gps-web/src/components/reports/MonthlySummaryReport.tsx`  
**Detail:**
- MonthlySummaryReport ปัจจุบันใช้ `month: Date` state (บรรทัด 76)
- **เปลี่ยนเป็น:** `dateRange: [Date, Date]`
- เพิ่ม DateTimeRangePicker
- Preset buttons ยังใช้งานได้:
  ```typescript
  // เมื่อกด "เดือนนี้" → setDateRange([startOfMonth(now), endOfMonth(now)])
  // เมื่อกด "เดือนที่แล้ว" → setDateRange([startOfMonth(subMonths(now, 1)), endOfMonth(subMonths(now, 1))])
  ```
- Wire เข้า `useMonthlySummaryReport()` hook → แก้ signature เป็น `(vehicleId, dateRange)` แทน `(vehicleId, month)`

---

### Phase 3: ปรับปรุง Summary Modal

**Checkpoint:** Summary Modal แสดงข้อมูลครบตามที่ user ต้องการ

**T005** dev-builder — รีดีไซน์ `SummaryModal.tsx`  
**File:** `bellerox-gps-web/src/components/reports/SummaryModal.tsx`  
**Detail:**

**3.1 เอา emoji ออกจากหัวข้อ**
- บรรทัด 44: `📊 สรุปรายงาน` → `สรุปรายงาน`

**3.2 เพิ่ม KPI ใหม่ในทุก tab**

สร้าง comprehensive KPI calculator:

```typescript
// ใน SummaryModal.tsx
interface ComprehensiveKPI {
  // มีอยู่แล้ว
  totalDistance: number;      // กม.
  totalEngineHours: number;   // ชม.
  maxSpeed: number;           // km/h
  totalFuel: number;          // ลิตร
  
  // เพิ่มใหม่
  totalStoppedTime: number;   // นาที (เวลาจอดรถ ignition OFF)
  totalIdleTime: number;      // นาที (เวลาจอดติดเครื่อง ignition ON)
  avgSpeed: number;           // km/h (ความเร็วเฉลี่ย)
  totalPTOHours: number;      // ชม. (เวลา PTO เปิด)
  fuelCost: number;           // บาท (ค่าน้ำมัน = fuel × 35)
  tripCount: number;          // จำนวนเที่ยว
}

function calculateComprehensiveKPI(data: any[], tab: Tab): ComprehensiveKPI {
  // Implementation logic
  // - trips tab: คำนวณจาก trip data
  // - alerts tab: คำนวณจาก event data
  // - summary tab: คำนวณจาก monthly summary
  
  const totalDistance = data.reduce((sum, r) => sum + (parseFloat(r.distance) || 0), 0);
  const totalDuration = data.reduce((sum, r) => sum + (parseDuration(r.duration) || 0), 0);
  const avgSpeed = totalDuration > 0 ? totalDistance / (totalDuration / 60) : 0;
  const totalFuel = data.reduce((sum, r) => sum + (parseFloat(r.fuelConsumption) || 0), 0);
  const fuelCost = totalFuel * 35; // diesel ~35 THB/L
  
  // PTO hours: sum from attributes.hours (if available)
  // Stopped time: duration when status = "จอดรถ,ดับเครื่องยนต์"
  // Idle time: duration when status = "จอดรถ,เครื่องยนต์ทำงาน"
  
  return { ... };
}
```

**3.3 Layout ใหม่: Grid 3 columns**

```tsx
<div className="grid grid-cols-3 gap-4">
  <StatCard label="รวมระยะทาง" value={`${kpi.totalDistance.toFixed(1)} กม.`} />
  <StatCard label="ความเร็วเฉลี่ย" value={`${kpi.avgSpeed.toFixed(0)} km/h`} />
  <StatCard label="ความเร็วสูงสุด" value={`${kpi.maxSpeed.toFixed(0)} km/h`} />
  
  <StatCard label="เวลาเครื่องยนต์ทำงาน" value={`${kpi.totalEngineHours.toFixed(1)} ชม.`} />
  <StatCard label="เวลาจอดรถ" value={`${(kpi.totalStoppedTime / 60).toFixed(1)} ชม.`} />
  <StatCard label="เวลาจอดติดเครื่อง" value={`${(kpi.totalIdleTime / 60).toFixed(1)} ชม.`} />
  
  <StatCard label="ใช้น้ำมันทั้งหมด" value={`${kpi.totalFuel.toFixed(1)} ลิตร`} />
  <StatCard label="ค่าน้ำมัน" value={`฿${kpi.fuelCost.toLocaleString('th-TH', {minimumFractionDigits: 2})}`} />
  <StatCard label="เวลา PTO เปิด" value={`${kpi.totalPTOHours.toFixed(1)} ชม.`} />
  
  <StatCard label="จำนวนเที่ยว" value={String(kpi.tripCount)} />
</div>
```

**3.4 แยก KPI ตาม tab:**
- **trips tab:** แสดง KPI ข้างบน + ไม่แสดง breakdown (รายละเอียดอยู่ในตารางหลักอยู่แล้ว)
- **alerts tab:** แสดง KPI ข้างบน + breakdown by alert type (มีอยู่แล้ว)
- **summary tab:** แสดง KPI overview ของเดือน

**3.5 Responsive:**
- Mobile (< 640px): `grid-cols-1` (1 column)
- Tablet (640-1024px): `grid-cols-2` (2 columns)
- Desktop (> 1024px): `grid-cols-3` (3 columns)

---

### Phase 4: QC + Build Verification

**Checkpoint:** ทุกอย่างทำงานได้ไม่มี error + responsive

**T006** test-runner — ทดสอบ UI + build  
**Detail:**
- **Browser test:**
  - เปิด `http://localhost:5173/app/reports`
  - ทดสอบ date/time picker ใน Daily Trip Report
  - เลือกวันที่ custom → ดูว่าตารางอัพเดท
  - ทดสอบ preset buttons (วันนี้/เมื่อวาน) → ยังทำงานได้
  - กดปุ่ม "ดูสรุป" → Summary Modal แสดงข้อมูลครบ, ไม่มี emoji
  - ทดสอบ 3 tabs ทั้งหมด
  
- **Mobile test:**
  - เปิด DevTools → responsive mode → 375px
  - ตรวจสอบ DateTimeRangePicker stack vertically
  - ตรวจสอบ Summary Modal grid-cols-1
  
- **Build test:**
  ```bash
  cd bellerox-gps-web
  npm run build
  ```
  - **Expected:** zero TypeScript errors
  - **Expected:** zero ESLint warnings

**T007** test-runner — Final commit  
**Detail:**
- `git status` → check modified files
- `git add bellerox-gps-web/src/components/`
- `git commit -m "feat(reports): add custom date/time range picker + comprehensive summary modal"`
- `git push origin main`
- Check CI → green ✓

---

## 📊 Estimated Timeline

- Phase 1: ~15 นาที (DateTimeRangePicker component)
- Phase 2: ~20 นาที (เพิ่ม picker ใน 3 reports)
- Phase 3: ~25 นาที (ปรับ Summary Modal)
- Phase 4: ~10 นาที (QC + build)
- **รวม:** ~70 นาที

---

## 🤖 Agent Assignment

- **T001:** ui-builder (สร้าง component)
- **T002-T004:** dev-builder (wire logic + hooks)
- **T005:** dev-builder (KPI calculation + redesign modal)
- **T006-T007:** test-runner (verification + commit)

---

## 📝 Notes

- HTML5 `<input type="date">` และ `<input type="time">` support ใน modern browsers ทั้งหมด
- ถ้า browser เก่าไม่ support → fallback เป็น text input
- Preset buttons ยังคงไว้เพราะ user ส่วนใหญ่ใช้ preset (UX convenience)
- ค่าน้ำมันคำนวณจาก: `totalFuel × 35 THB/L` (ราคา diesel ประมาณ Thailand 2026)
- PTO hours: ดึงจาก `attributes.hours` ของ position data (ถ้ามี)
- Summary Modal: ข้อมูลบางตัวอาจไม่มี (PTO, fuel) → แสดง "—" หรือ "ไม่มีข้อมูล"

---

**Status:** `approved`  
**Approved:** 2025-08-12  
**Executing:** THE TOH LOOP
