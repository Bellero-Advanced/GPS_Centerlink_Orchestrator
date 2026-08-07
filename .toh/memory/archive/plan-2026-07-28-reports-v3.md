# 📊 Unified Reports Page + Reload Bug Fix

**Status:** `approved`
**Goal:** รวมหน้า "รายงาน" + "รายงานขั้นสูง" เป็น 2-panel layout เดียว · แก้ bug reload→login · fix font IBM Plex Sans Thai

---

## 🎯 Done When

- [ ] Reload หน้าใดก็ตามใน /app → ยังอยู่หน้าเดิม ไม่เด้ง login
- [ ] มีหน้า Reports เดียวที่ `/app/reports` — sidebar ซ้าย category tree, panel ขวา content
- [ ] 3 reports ที่มี ⚡ (Daily Trip, Monthly Summary, Daily Alerts) แสดงตาราง live + export
- [ ] Reports อื่น (50+ แบบ) แสดง PDF preview button เหมือนเดิม
- [ ] ลบ `/app/reports-v3` route + เมนู "รายงานขั้นสูง" ออก
- [ ] Font = IBM Plex Sans Thai ทุก component รายงาน (ตาม DESIGN.md)
- [ ] CSS vars ตาม DESIGN.md: `--brand` `--surface-0` `--ink-1` `--ink-3` `--border`
- [ ] `npm run build` ผ่าน, CI green

---

## 📋 Phases & Tasks

### Phase 1: Bug Fix — Reload → Login

- **T001** `dev-builder` — แก้ `src/stores/authStore.ts`
  - login action: เขียน password ลง `sessionStorage` ด้วย (key `_c_gpw`)
  - เพิ่ม `restorePassword()` action ที่อ่าน sessionStorage กลับมา
  - logout action: ลบ sessionStorage key ด้วย

- **T002** `dev-builder` — แก้ `src/App.tsx`
  - เพิ่ม `useEffect` ที่ทำงาน 1 ครั้งตอน mount: ถ้า `isAuthenticated && !_password` → เรียก `restorePassword()` เพื่อดึง password กลับจาก sessionStorage
  - ถ้า sessionStorage ว่าง (ปิด tab แล้วเปิดใหม่) → `logout()` แสดง session expired toast

**Checkpoint Phase 1:** เปิด `/app/map` → F5 reload → ยังอยู่หน้าแผนที่ ไม่เด้ง login ✓

---

### Phase 2: Unified Reports Page

- **T003** `ui-builder` — สร้าง `src/pages/ReportsPageUnified.tsx`
  - Layout: 2-panel (sidebar 280px + main content)
  - Left sidebar: search bar + category accordion (จาก `REPORT_CATEGORIES` ใน reportTypes.ts)
  - แต่ละ report item ใน list: ถ้า report id อยู่ใน `LIVE_REPORT_IDS` → แสดง ⚡ badge
  - Right panel: `<ReportContent report={selected} />` (component ต่อจาก T004)
  - Font: IBM Plex Sans Thai, CSS vars ตาม DESIGN.md ทั้งหมด

- **T004** `dev-builder` — สร้าง `src/components/reports/ReportContent.tsx`
  - รับ `report: ReportConfig | null`
  - ถ้า `report.id` อยู่ใน LIVE_REPORT_IDS → render live component (Daily Trip / Monthly Summary / Daily Alerts)
  - ถ้าไม่ใช่ → render PDF preview panel (vehicle selector + date picker + Generate PDF button) จาก ReportsPageV2
  - เชื่อม export handlers เข้าทุก live report

- **T005** `dev-builder` — Migrate logic จาก `ReportsPageV2`
  - ย้าย PDF generation logic (REPORT_GENERATORS, SPECIAL_GENERATORS, printHTMLAsPDF) เข้า ReportContent
  - ใช้ hooks และ state ที่มีอยู่แล้ว ไม่ duplicate

- **T006** `ui-builder` — Update routes + nav
  - `src/App.tsx`: เปลี่ยน `path="reports"` ให้ point ไป `ReportsPageUnified`; ลบ `path="reports-v3"` และ lazy import
  - `src/components/layout/LayoutV2.tsx`: ลบ nav item "รายงานขั้นสูง" ออก, คง "รายงาน" ไว้

**Checkpoint Phase 2:** เปิด `/app/reports` → เห็น sidebar category tree → คลิก "Daily Trip" → ตาราง live โชว์ → Export PDF ได้ ✓

---

### Phase 3: Design Polish

- **T007** `design-reviewer` — Fix font stack ใน report components
  - `src/components/reports/SimpleReportTable.tsx`: ไม่มี hardcoded font — ใช้ inherit จาก parent (IBM Plex Sans Thai ที่ set ใน index.css ก็ครอบคลุมอยู่แล้ว)
  - แก้ `DailyTripReport.tsx`, `MonthlySummaryReport.tsx`, `DailyAlertsReport.tsx`: replace `var(--text-primary)` → `var(--ink-1)`, `var(--text-muted)` → `var(--ink-4)`, `var(--text-secondary)` → `var(--ink-3)`, `var(--bg-canvas)` → `var(--surface-0)`
  - แก้ `ExportButton.tsx`, `exportUtils.ts` ถ้ามี hardcoded colors

- **T008** `design-reviewer` — Fix SimpleReportTable visual
  - Header row: `font-size: 11px`, `font-weight: 600`, `letter-spacing: 0.08em`, `color: var(--ink-3)` (ตาม DESIGN.md tables spec)
  - Row hover: `background: var(--surface-2)`
  - Focus/active state ใช้ `--brand` (#ff788b) ไม่ใช่ blue
  - Pagination buttons: style ตาม DESIGN.md buttons spec

- **T009** `design-reviewer` — ReportsPageUnified design polish
  - Sidebar active item: `background: var(--brand-light)`, `color: var(--brand)`, `border-left: 3px solid var(--brand)`
  - ⚡ live badge: `background: rgba(255,120,139,0.1)`, `color: var(--brand)` (brand pink ไม่ใช่ yellow)
  - Category accordion header: `var(--ink-1)` font-weight 600
  - Panel header: IBM Plex Sans Thai, `var(--ink-1)`

**Checkpoint Phase 3:** หน้า Reports ดู on-brand — pink #ff788b, IBM Plex Sans Thai, ไม่มี hardcoded blue หรือ generic colors ✓

---

### Phase 4: Verify + Deploy

- **T010** `test-runner` — `npm run build` + ตรวจ TypeScript errors
  - Fix any remaining type errors

- **T011** `test-runner` — `npm run lint` (--max-warnings 60 threshold)
  - Fix lint errors (ESLint errors = 0, warnings < 60)

- **T012** `dev-builder` — Commit + push + verify CI green
  - Branch: `feature/unified-reports-reload-fix`
  - PR → CI → merge

**Checkpoint Phase 4:** CI run: tsc ✓ lint ✓ build ✓ deploy ✓

---

## ⏱️ Estimated Time

- Phase 1: ~10 min (2 files, clear root cause)
- Phase 2: ~25 min (new page + migration)
- Phase 3: ~15 min (CSS token sweep)
- Phase 4: ~15 min (build + CI)
**Total: ~65 min**

---

**Last Updated:** 2026-07-28
**Plan Version:** 2.0
