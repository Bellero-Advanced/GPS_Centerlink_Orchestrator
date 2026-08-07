# Reports System v2.1 — Advanced Report Categories
# Bellerox GPS · Inspired by GPS Thailand Co.,Ltd

## Design Principles

1. **8 Report Categories** — จัดกลุ่มรายงานให้หาง่าย
2. **Smart Filters** — DatePresets + Multi-vehicle + Quick chips
3. **Live Preview** — iframe แสดง PDF ก่อน download
4. **Auto-refresh** — toggle สำหรับ real-time reports
5. **Export Options** — PDF (preview + download) + CSV + Excel

---

## 8 Report Categories

### 1. **ประจำเดือน (Monthly Reports)** — 8 reports
- รายงานการเดินทางประจำเดือน
- รายงานสรุปประจำเดือน (summary stats)
- รายงานการขับรถประจำเดือน (driver behavior)
- รายงานสรุพฤติกรรมคนขับ (driver scoring)
- รายงานสรุปความเร็วประจำเดือน (speed summary)
- กราฟความเร็วรายเดือน (Pie Chart)
- กราฟวิเคราะห์พฤติกรรมการขับรถ (Chart)
- รายงานระยะทางรายเดือน (distance by vehicle)

### 2. **ความเร็ว (Speed Reports)** — 10 reports
- ความเร็วปัจจุบัน (live speed dashboard)
- ความเร็วเกิน (overspeed events)
- ความเร็วเกินโดยรวม (overspeed summary)
- ความเร็วเกิน ณ ช่วงเวลา (time-based overspeed)
- รายงานสรุปความเร็วเกิน (overspeed by vehicle)
- ความเร็ว ณ จุด POI (speed at POI zones)
- รายงานช่วงความเร็ว (speed range distribution)
- กราฟความเร็ว (Area Chart)
- กราฟความเร็ว (Pie Chart)
- กราฟสรุปความเร็วเกินและสูงสุด

### 3. **เชื้อเพลิง (Fuel Reports)** — 8 reports
- กราฟการใช้น้ำมัน (fuel consumption chart)
- กราฟน้ำมันคงเหลือในถัง (fuel level chart)
- กราฟการใช้แก๊ส (CNG/LPG chart)
- วิเคราะห์การใช้น้ำมัน (fuel efficiency)
- วิเคราะห์การใช้น้ำมัน (แบบวัน) (daily fuel)
- วิเคราะห์การใช้น้ำมัน (ตามสถานะ) (by vehicle status)
- วิเคราะห์การใช้แก๊ส (CNG/LPG efficiency)
- การเปลี่ยนแปลงน้ำมัน (fuel drop alerts — theft detection)

### 4. **การบำรุงรักษา (Maintenance Reports)** — 5 reports
- รายงานการตรวจเช็ค/เปลี่ยนถ่าย น้ำมันเครื่อง
- รายงานการตรวจเช็คระยะของยางรถยนต์
- รายงานการตรวจเช็คระยะของสายพาน
- รายงานการตรวจเช็คลูกยางแท้นเครื่อง
- รายงานเช็ควันหมดอายุ ประกัน พรบ ภาษี

### 5. **จุดจอด / POI (Parking & POI Reports)** — 12 reports
- จุดจอดตาม POI (parking at POI zones)
- รถเข้าออกจุดจอดรถ POI (POI entry/exit)
- การจอด/หยุดรถ (stop report)
- การจอดรถ/หยุดรถโดยรวม (stop summary)
- รายงานเส้นทางการวิ่งตามจุดจอด (route via POI)
- ระยะทางระหว่างจุดจอด (distance between stops)
- การวิ่งงานรถและการจอดรถ (trips + stops combined)
- รถเข้าจุดจอด POI (POI arrival log)
- ระยะทางจุดจอดแรก-จุดจอดสุดท้าย (first-last distance)
- ระยะทางจุดจอดแรก-สุดท้าย (Multi select)
- จุดจอดตาม POI (Multi select)
- รายงานการเดินทาง ต้นทาง-ปลายทาง

### 6. **แจ้งเตือน (Alert Reports)** — 10 reports
- รายงานสถานะ (vehicle status changes)
- รายงานรถเข้าออกขอบเขต (geofence violations)
- ขับรถต่อเนื่องนานเกิน (continuous driving alert)
- การจอดรถ (parking alerts)
- รายงานการเปาลมเซ็นเซอร์ปั้น (sensor alerts)
- แจ้งเตือนรถเข้า-ออกจุดจอดเกินเวลา (POI timeout)
- รายงานประวัติการเข้าใช้งานระบบ (system access log)
- แจ้งเตือนจาก GPS
- แจ้งเตือนจาก MDVR (dashcam alerts)
- แจ้งเตือนจาก JC (job control alerts)

### 7. **การเดินทาง (Trip Reports)** — 6 reports
- รายงานการเดินทางประจำวัน (daily trips)
- รายงานการเดินทางโดยรวม (trip summary)
- รายงานการเดินทาง ต้นทาง-ปลายทาง (origin-destination)
- รายงานเส้นทาง (route playback)
- รายงานระยะทางรายยานพาหนะ (distance by vehicle)
- รายงาน Trip ที่ไม่สมบูรณ์ (incomplete trips — engine off mid-route)

### 8. **วิเคราะห์ขั้นสูง (Advanced Analytics)** — 8 reports
- OCR (license plate recognition from dashcam)
- รายงานข้อมูลสรุปปัจจุบัน (real-time fleet dashboard)
- รายงาน ECU (engine control unit data)
- กราฟการใช้แก๊ส (gas consumption trends)
- วิเคราะห์พฤติกรรมการขับ (driver behavior analytics)
- รายงานประสิทธิภาพฝูงบิน (fleet efficiency score)
- รายงานการใช้งานยานพาหนะ (vehicle utilization %)
- รายงานต้นทุนการดำเนินงาน (operating cost analysis)

---

## UI/UX Design — ReportsPage v2.1

### Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│ PageHeader: รายงาน                  [🔍 ค้นหา...]      │
├─────────────────────────────────────────────────────────┤
│ [Category Pills: ประจำเดือน | ความเร็ว | เชื้อเพลิง...] │
├─────────────────────────────────────────────────────────┤
│ ┌───────────────────┬───────────────────────────────────┐│
│ │ Report List       │ Preview / Filters                 ││
│ │ (left sidebar)    │ (main area)                       ││
│ │                   │                                   ││
│ │ ✓ การเดินทาง...  │ [Date Presets: วันนี้|สัปดาห์...]││
│ │   ความเร็วเกิน    │ [Vehicle Multi-Select]            ││
│ │   จุดจอด POI      │ [Auto-refresh toggle]             ││
│ │   ...             │                                   ││
│ │                   │ [Preview iframe — PDF embed]      ││
│ │                   │                                   ││
│ │                   │ [Download PDF] [Export CSV]       ││
│ └───────────────────┴───────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

### Category Pills (Top Navigation)

```tsx
<div className="flex gap-2 overflow-x-auto pb-2 no-scrollbar">
  {CATEGORIES.map(cat => (
    <button
      key={cat.id}
      className={clsx('chip', activeCategory === cat.id && 'chip-brand')}
      onClick={() => setActiveCategory(cat.id)}
    >
      <cat.icon size={14} />
      {cat.label}
      <span className="ml-1 opacity-60">({cat.count})</span>
    </button>
  ))}
</div>
```

### Report List Sidebar (Collapsible on mobile)

```tsx
<div className="w-64 flex-shrink-0 border-r" style={{ borderColor: 'var(--border)' }}>
  <input
    className="input mb-2"
    placeholder="ค้นหารายงาน..."
    value={search}
    onChange={e => setSearch(e.target.value)}
  />
  {filteredReports.map(report => (
    <button
      key={report.id}
      className={clsx('report-item', activeReport === report.id && 'active')}
      onClick={() => setActiveReport(report.id)}
    >
      <report.icon size={16} />
      <span>{report.name}</span>
      {report.multiSelect && <Badge>Multi</Badge>}
    </button>
  ))}
</div>
```

### Main Preview Area

```tsx
<div className="flex-1 flex flex-col gap-4 p-6">
  {/* Filters row */}
  <div className="flex gap-3 flex-wrap">
    <DatePresets value={dateRange} onChange={setDateRange} />
    <VehicleMultiSelect selected={vehicles} onChange={setVehicles} />
    <Toggle label="อัพเดตอัตโนมัติ" checked={autoRefresh} onChange={setAutoRefresh} />
  </div>

  {/* Preview iframe */}
  <div className="flex-1 bg-white rounded-xl shadow-sm overflow-hidden">
    {previewLoading ? (
      <div className="skeleton h-full" />
    ) : (
      <iframe
        ref={iframeRef}
        className="w-full h-full border-0"
        title="PDF Preview"
      />
    )}
  </div>

  {/* Actions */}
  <div className="flex justify-end gap-2">
    <button className="btn btn-secondary" onClick={handleDownloadPDF}>
      <FileText size={14} /> ดาวน์โหลด PDF
    </button>
    <ExportMenu onExport={handleExport} formats={['csv', 'excel']} />
    <button className="btn btn-secondary" onClick={handlePrint}>
      <Printer size={14} /> พิมพ์
    </button>
  </div>
</div>
```

---

## Implementation Plan — Phased Rollout

### Phase 1: Core Architecture (Day 1)
- ✅ reportPDFService.ts (done)
- ✅ reportTemplates.ts with 10 generators (done)
- ⬜ ReportsPageV2.tsx — new file with category navigation
- ⬜ Report registry — centralized list of all 67 reports
- ⬜ PDF preview iframe component

### Phase 2: Priority Reports (Day 2-3)
Implement 20 most-used reports first:
1. รายงานการเดินทางประจำเดือน
2. ความเร็วเกิน
3. จุดจอดตาม POI
4. รายงานสรุปประจำเดือน
5. การจอด/หยุดรถ
6. รายงานเชื้อเพลิง
7. รายงานการบำรุงรักษา
8. แจ้งเตือนจาก GPS
9. รายงานพฤติกรรมคนขับ
10. ระยะทางรายยานพาหนะ
... (10 more)

### Phase 3: Advanced Reports (Day 4-5)
- OCR integration
- ECU data reports
- Cost analysis
- Fleet efficiency scoring
- MDVR/JC integrations

### Phase 4: Polish & Deploy (Day 6)
- PDF preview optimization
- Mobile responsive
- Loading states
- Error handling
- Deploy + user testing

---

## Data Sources

| Report Category | Data Source | API Endpoint |
|----------------|-------------|--------------|
| Trips | Traccar | `/api/reports/trips` |
| Speed | Traccar | `/api/reports/summary` + `/api/events?type=deviceOverspeed` |
| Fuel | Traccar positions | `position.attributes.fuel` |
| Stops | Traccar | `/api/reports/stops` |
| Alerts | Traccar | `/api/events` |
| Maintenance | localStorage | `bellerox-maintenance-records` |
| POI | Traccar | `/api/geofences` + `/api/events?type=geofence*` |
| Analytics | Computed | Aggregate from multiple sources |

---

## Next Steps

1. Create `src/pages/ReportsPageV2.tsx` with category navigation
2. Create `src/components/ReportPreview.tsx` for iframe PDF preview
3. Create `src/lib/reportRegistry.ts` with all 67 report definitions
4. Wire up 20 priority reports with PDF generators
5. Deploy + iterate
