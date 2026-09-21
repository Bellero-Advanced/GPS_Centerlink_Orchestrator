# DESIGN.md — Bellerox GPS

## 1. Identity & Atmosphere

Night-shift fleet control — dispatch consoles, illuminated city maps, operator focus under low light. The world: radar screens, logistics hubs at 3am, monochrome vehicle manifests, GPS coordinates in backlit panels. Thesis: a professional operations center, not a consumer app — cool slate surfaces, data-dense tables, utilitarian grids, status colors that cut through darkness.

**Signature element:** tabular-nums coordinate display — lat/lng pairs set huge in JetBrains Mono, the visual anchor of every vehicle card. Position data is the hero, not decoration.

## 2. Color Palette & Roles

| Token | Light | Dark | Role |
|---|---|---|---|
| --surface-0 | #FFFFFF | #202124 | card/panel background |
| --surface-1 | #F8F9FA | #171717 | page background (cool slate-biased neutral) |
| --surface-2 | #F1F3F4 | #292A2D | input fills, muted sections |
| --surface-3 | #E8EAED | #3C4043 | hover states, table headers |
| --ink-1 | #202124 | #E8EAED | primary text |
| --ink-2 | #3C4043 | #BDC1C6 | secondary text |
| --ink-3 | #5F6368 | #9AA0A6 | muted labels |
| --brand | #FF788B | #FFAAB8 | brand accent — CTAs, active nav (tenant-configurable, default shown) |
| --border | #DADCE0 | #3C4043 | dividers, card edges |

**Status colors (IMMUTABLE — users internalize these):**  
`--moving: #34A853` (green) · `--idle: #FBBC04` (amber) · `--stopped: #EA4335` (red) · `--offline: #5F6368` (grey)

Semantic (separate from brand): `--critical: #EA4335` · `--warning: #FBBC04` · `--success: #34A853`

Palette source: night-shift logistics operations — radar displays, backlit control panels, monochrome manifests with status indicators.

## 3. Typography

**Display/Body:** IBM Plex Sans Thai 300/400/500/600/700 (Thai + English, weights 300-700)  
**Utility/mono:** JetBrains Mono 400/500/600 — coordinates, speeds, device IDs, vehicle codes (tabular-nums always)

Scale ratio: 1.2 · Hero: 2xl-3xl (30-36px) · Body: sm-base (13-14px) · Measure: 70ch  
Numbers in tables/stats: `font-mono tabular-nums` — GPS data updates every 10s, layout must not reflow.

## 4. Component Styling

**Buttons:** squared, radius 4px, solid brand primary, 1px border outline secondary, danger uses `rgba(234,67,53,0.08)` fill  
**Cards:** flat border + subtle shadow (no glassmorphism), radius 6px, hover lifts shadow to `--shadow-md`  
**Inputs:** color-fill (no border) — `--surface-2` fill, focus = `--surface-3` + brand ring, radius 4px  
**Tables:** dense 13px rows, `--surface-2` header band, hover row = `--surface-1`, right-aligned actions  
**Radius cap:** 12px (cards/dialogs only) — buttons/inputs stay at 4-6px

## 5. Layout & Navigation

**Nav pattern:** Dashboard/app — left sidebar (240px) with labeled icons, grouped by function (Core / Operations / Management / Settings), collapsible on tablet  
**Spacing rhythm:** 4px base, 16px element gap, 24px card padding, 48px major sections  
**Logo expression:** top-left, clickable-to-home; wordmark "Bellerox GPS" in IBM Plex Sans Thai 600 with a 3px accent line below in brand color, sits above the nav groups.

## 6. Depth & Elevation

Border-first. Shadows only on cards (sm) and modals (lg). Hover state = shadow lift from sm → md (120ms linear transition). No glassmorphism, no gradient borders, no dramatic depth — operational clarity over decoration.

## 7. Iconography

**Library:** Lucide (regular weight) · **Stroke:** 1.5px · **Sizes:** 16px (inline) / 20px (nav) / 24px (headers)  
Labels required on all nav items and icon-only buttons (`aria-label`). No emoji as icons. True universals (search, close ×, chevron) can omit visible labels.

## 8. Motion & Copy Voice

**Motion:** 100-150ms ease-out; hover = background darkens or shadow lifts; no scale, no bounce, no width/height animation (GPS data updates are frequent, motion must not lag). Status changes = instant (no animation — safety info appears immediately). Respect `prefers-reduced-motion` always.

**Case system:** Sentence case (Thai + English) — buttons state exact outcomes: "บันทึกข้อมูล" / "Save vehicle", never vague "Submit" / "Continue".

**Button verbs (Thai):** บันทึก (save) · ยกเลิก (cancel) · ลบ (delete) · แก้ไข (edit) · ดูรายละเอียด (view details) · ติดตาม (track)

**Errors:** state what failed + the fix, no apology — "เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ — ตรวจสอบอินเทอร์เน็ต" (Connection failed — check internet), not "โอ๊ะ! มีบางอย่างผิดพลาด 😢".

## 9. Do's & Don'ts + Agent Prompt Guide

**Do:**  
- Lead vehicle cards with coordinate display (lat/lng in mono, large)  
- Keep tables dense — fleet managers scan 50-200 vehicles at once  
- Show status with semantic tokens (moving/idle/stopped/offline colors are fixed)  
- Use color-fill inputs (no borders) per the existing codebase pattern  
- Dark mode is mandatory (night-shift operators)

**Don't:**  
- Warm cream/terracotta palettes (this is operations, not lifestyle)  
- Purple/indigo gradients or glow effects (no "futuristic AI dashboard" look)  
- Icon tiles above headings (the #1 AI tell)  
- Rounded-3xl cards or glassmorphism  
- Change status colors (green/amber/red/grey are internalized by users)  
- Everything in design-craft/AVOID-LIST.md

**Agents:** re-read this file before EVERY UI task; every color/typeface/radius/motion value must trace to sections 2-8. Never work from memory of this file.

## Distinctiveness check (REQUIRED)

The category default is a bright white dashboard with purple gradients, rounded cards, Inter as display, and "welcoming" empty states. **Rejected:** this is a 24/7 night-shift fleet operations tool — cool slate neutrals (not warm), squared industrial components (not rounded consumer UI), JetBrains Mono coordinate numerals as the hero (not decoration), dark mode mandatory (not optional), and status colors that survive low-light glare. No other GPS tracking brief would produce IBM Plex Sans Thai + tabular coordinate display + borderless color-fill inputs + operations-grade density. This design reads "professional logistics control center", never "consumer location app".

---

## 16. Integration UX Patterns (v3.0)

### 16.1 LINE Notify — Setup Wizard
```
DO NOT use a single token input field.
Use a 3-step wizard:

Step 1 — Connect
  Title: "เชื่อมต่อ LINE Notify"
  [LINE green button: "เปิด LINE Notify website"]
  Instructions: "1. เข้าสู่ระบบด้วย LINE 2. เลือก 'Generate token' 3. วาง token ด้านล่าง"

Step 2 — Verify
  [Token input: masked, type="password", show/hide toggle]
  [ทดสอบการเชื่อมต่อ button] → sends "✅ เชื่อมต่อสำเร็จ" to LINE
  Status: connecting spinner → success checkmark or error

Step 3 — Configure
  [Multi-select: alert types to send to this token]
  [บันทึก button]

Token display: ALWAYS masked (••••••••••••abc123) — never show full token
```

### 16.2 DLT GPS Web Service
```
Layout: Card with "Connection Status" header badge (Connected/Disconnected)

Sections:
  1. Credentials (Vendor ID + username + password)
  2. Auto-send toggle + interval
  3. Connection test button + last sync timestamp
  4. Error log (last 10 errors, collapsible)

"ทดสอบการเชื่อมต่อ" button behavior:
  → Spinner during test (max 10s timeout)
  → Toast: "เชื่อมต่อสำเร็จ — DLT ID: XXXX" or error
  → Update last_tested_at timestamp
```

### 16.3 CSV/PDF Export UX
```
Export button behavior:
  1. Click → immediately show "กำลังสร้างไฟล์..." overlay
  2. Generate → trigger browser download
  3. Toast: "ดาวน์โหลดแล้ว — fleet_report_2026-07-04.csv"

Filename convention: [type]_[YYYY-MM-DD].csv
  trips_2026-07-04.csv
  alerts_2026-07-04.csv
  fleet_summary_2026-07-04.csv

CSV must include: UTF-8 BOM (for Excel Thai character support)
  Add: '﻿' + csvContent
```

### 16.4 API Documentation (Pro Tier)
```
Add /app/api-docs page (settings section):
  - Base URL display + copy button
  - Authentication method (Basic Auth)
  - Quick-start code snippet (curl + JavaScript)
  - Link to full Traccar API docs: https://www.traccar.org/api-reference/

This page exists to support Pro tier upsell and partner integrations.
```

---

## 17. Onboarding & First-Use Patterns (v3.0)

### 17.1 First Login — Empty Fleet
```
If devices.length === 0 after login:
  Redirect to /app/fleet with onboarding overlay:
    Step 1: "เพิ่มยานพาหนะแรกของคุณ"
    Step 2: "ตั้งค่า APN และ Server IP บน GPS device"
    Step 3: "รอ GPS ส่งข้อมูล (ปกติภายใน 2 นาที)"

  Show "Skip onboarding" link (small, bottom-right)
  Don't show again: store in localStorage 'onboarding_completed'
```

### 17.2 Feature Discovery Hints
```
Geofence page (first visit):
  Show tooltip: "คลิกที่แผนที่เพื่อเริ่มวาดโซน"
  Dismiss: click anywhere outside tooltip

Scoring page (first visit):
  Show info banner: "คะแนนเริ่มต้นที่ 100 — หักคะแนนตามพฤติกรรมการขับ"
  Include link to scoring breakdown

Keyboard shortcuts (all pages):
  '?' key → opens KeyboardShortcutsModal
  Hint text in page footer (small, ink-4): "กด ? สำหรับ keyboard shortcuts"
```

---

## 18. Mobile & Responsive Design (v3.0)

### 18.1 Breakpoints (strict)
```
Mobile:   375–639px   → single column, bottom nav, map full screen
Tablet:   640–1023px  → collapsible sidebar (hidden by default)
Desktop:  1024px+     → full two-column layout, expanded sidebar
Large:    1440px+     → max-width containers kick in

Minimum supported: 375px (iPhone SE) — TEST ON THIS SIZE
```

### 18.2 Mobile Navigation Pattern
```
Mobile: Fixed bottom nav bar (4 items only)
  - แผนที่ (LiveMap) — primary action, center
  - กองยาน (Fleet)
  - แจ้งเตือน (Alerts) + badge count
  - โปรไฟล์ (Account)

Height: 56px + safe area inset (env(safe-area-inset-bottom))
Background: --surface-0 with top border --border
Active item: --brand color, filled icon

All other pages: accessible via profile menu on mobile
```

### 18.3 Touch Interaction Rules
```
Minimum tap target: 44×44px (NEVER smaller)
Swipe gestures (vehicle list):
  → Swipe RIGHT: call driver (trigger tel: link)
  → Swipe LEFT: view on map (navigate to /app/map?vehicle=X)

Long press (vehicle marker on map):
  → Show context menu: ดูรายละเอียด | ประวัติเส้นทาง | ส่งคำสั่ง

Scroll behavior:
  Momentum scrolling: -webkit-overflow-scrolling: touch
  Pull-to-refresh: implement on vehicle list (refreshes positions)
```

---

## 19. Performance Perception (v3.0)

These rules make the app FEEL fast even when data is loading.

### 19.1 Skeleton Screens — Required Pages
```
Page              Skeleton Elements
──────────────────────────────────────────────
Dashboard         4 KPI card skeletons + 5 table row skeletons
Fleet             Table: 8 row skeletons, 4 columns each
Alerts            5 row skeletons with badge placeholder
Drivers           6 card skeletons (grid or list)
Reports           Date picker + 3 row skeletons

NO skeleton needed: Map (shows empty tiles immediately), Settings (instant)
```

### 19.2 Optimistic Updates
```
Apply optimistic updates for:
  - Toggle alert rules (immediate toggle, revert on error)
  - Dismiss notification (immediate remove, revert on error)
  - Mark maintenance done (immediate badge update)

DO NOT apply optimistic updates for:
  - Delete vehicle (too destructive, wait for confirmation)
  - Send device command (wait for server response)
```

### 19.3 Progressive Data Loading
```
Dashboard: load KPI cards first (lightweight /api/devices)
           then load event count (secondary)
           charts load last (or on scroll-into-view)

Fleet page: load device list first
            then load current positions (secondary request)
            merge into VehicleWithPosition after both resolve

Live Map: render map tiles immediately
          show loading spinner on vehicle panel
          add markers as positions arrive (batch by 50ms)
```

---

## 20. Data Visualization Standards (v3.0)

### 20.1 Chart Types — When to Use
```
Line chart:     Speed over time, fuel over time, score trend
Bar chart:      Distance per vehicle per day, trips per driver
Donut/Pie:      Fleet status breakdown (4 status colors only)
Sparkline:      Score trend in driver card (compact, no axes)
Gauge:          Single score display (0-100), health score
Table+heatmap:  Alert frequency by day/hour grid

NEVER use: 3D charts, area charts (use line), bubble charts
```

### 20.2 Recharts Implementation Rules
```typescript
// Standard chart colors — always use these
const CHART_COLORS = {
  moving:  '#34A853',
  idle:    '#FBBC04',
  stopped: '#9AA0A6',
  offline: '#EA4335',
  primary: '#1A73E8',
  secondary: '#FA7B17',
}

// Standard chart config
const CHART_DEFAULTS = {
  margin: { top: 4, right: 16, bottom: 4, left: 0 },
  fontSize: 12,
  fontFamily: '"IBM Plex Sans Thai", system-ui',
}
```

### 20.3 Real-time Number Updates
```
Numbers that update in real-time (speed, position, time):
  - Must use JetBrains Mono + tabular-nums to prevent layout shift
  - Wrap in <span className="font-mono tabular-nums">
  - Transition: none (instant update is correct for real-time data)
  - Format: always include unit: "67 km/h" not "67"
```

---

## 21. Implemented Patterns Catalog (v3.0 — 2026-07-04)

These patterns were implemented during the UX/UI audit upgrade. Copy-paste these
exact patterns when building new pages or features.

### 21.1 Dismissible Info Banner
Used in: ScoringPage (score breakdown), Settings onboarding

```tsx
// Dismissible explanation banner — persists dismissal in localStorage
function InfoBanner({ storageKey, children }: { storageKey: string; children: React.ReactNode }) {
  const [visible, setVisible] = useState(() =>
    localStorage.getItem(storageKey) !== 'true'
  );
  if (!visible) return null;
  return (
    <div
      className="mx-6 mt-4 rounded-lg flex items-start gap-3 px-4 py-3"
      style={{ background: 'rgba(26,115,232,0.07)', border: '1px solid rgba(26,115,232,0.20)' }}
    >
      <span style={{ color: 'var(--brand)', marginTop: 1 }}>ℹ️</span>
      <div className="flex-1 text-xs" style={{ color: 'var(--ink-2)' }}>{children}</div>
      <button
        onClick={() => { localStorage.setItem(storageKey, 'true'); setVisible(false); }}
        className="flex-shrink-0 text-xs"
        style={{ color: 'var(--ink-4)' }}
        aria-label="ปิด"
      >✕</button>
    </div>
  );
}
```

### 21.2 First-Time Feature Hint (Draw Mode)
Used in: GeofencesPage

```tsx
// First-time contextual hint — shows when a feature is first used
const [showHint, setShowHint] = useState(() =>
  localStorage.getItem('feature_xyz_hinted') !== 'true'
);

{showHint && (
  <div className="mx-3 my-2 rounded-lg px-3 py-2 flex items-start gap-2"
    style={{ background: 'rgba(26,115,232,0.08)', border: '1px solid rgba(26,115,232,0.25)' }}
  >
    <span style={{ fontSize: 16, lineHeight: 1.4 }}>👆</span>
    <div className="flex-1">
      <p className="text-xs font-semibold" style={{ color: 'var(--brand)' }}>
        คำแนะนำการใช้งาน
      </p>
    </div>
    <button
      className="text-xs flex-shrink-0"
      style={{ color: 'var(--ink-4)' }}
      onClick={() => { localStorage.setItem('feature_xyz_hinted', 'true'); setShowHint(false); }}
    >✕</button>
  </div>
)}
```

### 21.3 Initials Avatar (Colorful Fallback)
Used in: DriversPage, TeamPage

```tsx
// Colorful initials avatar — use when no photo is available
function InitialsAvatar({ name, id, size = 40 }: { name: string; id: number; size?: number }) {
  const COLORS = ['#1A73E8','#34A853','#FA7B17','#EA4335','#9C27B0','#00ACC1'];
  const initials = name.trim().split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase();
  return (
    <div
      className="rounded-full flex items-center justify-center text-white font-bold select-none flex-shrink-0"
      style={{
        width: size, height: size,
        fontSize: size * 0.35,
        background: COLORS[id % COLORS.length],
      }}
      title={name}
    >
      {initials}
    </div>
  );
}
// Usage: replace <UserCircle> fallback with <InitialsAvatar name={user.name} id={user.id} />
```

### 21.4 Sticky Settings TOC (Two-Column Layout)
Used in: SettingsPage

```tsx
// Two-column settings layout with sticky left TOC
// Apply when settings page content exceeds 3 sections
<div className="flex gap-8 mx-auto" style={{ maxWidth: 960 }}>

  {/* Sticky TOC — desktop only, hidden on mobile */}
  <aside className="hidden lg:block flex-shrink-0"
    style={{ width: 176, position: 'sticky', top: 80, alignSelf: 'flex-start' }}>
    <p className="section-label mb-3">เนื้อหา</p>
    <nav className="flex flex-col gap-0.5">
      {sections.map(({ id, label }) => (
        <a key={id} href={`#${id}`}
          onClick={e => { e.preventDefault(); document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' }); }}
          className="text-xs rounded-md px-2.5 py-1.5 transition-colors"
          style={{ color: 'var(--ink-3)', textDecoration: 'none' }}
          onMouseEnter={e => (e.currentTarget.style.background = 'var(--surface-2)')}
          onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
        >{label}</a>
      ))}
    </nav>
  </aside>

  {/* Main content — each section gets an id for scroll-to */}
  <div className="flex-1 space-y-8 min-w-0">
    <div id="section-one"><SectionOne /></div>
    <div id="section-two"><SectionTwo /></div>
  </div>
</div>
```

### 21.5 License Plate Column in Data Tables
Used in: FleetPage

```
Rule: Any table listing vehicles MUST include ทะเบียน as the 2nd column.
Thai fleet operators identify vehicles by license plate, not by device name.

<th>ทะเบียน</th>  ← always 2nd column, after ชื่อ

<td>
  <span className="num text-xs font-mono"
    style={{ color: vehicle.contact ? 'var(--ink-2)' : 'var(--ink-4)' }}>
    {vehicle.contact || '—'}
  </span>
</td>
```

### 21.6 Recurring Schedule Pattern
Used in: MaintenancePage

```typescript
// Recurrence type — use for any schedulable item
type Recurrence = 'none' | 'monthly' | 'quarterly' | 'biannual' | 'annual';

const RECURRENCE_OPTIONS = [
  { value: 'none',      label: 'ไม่ซ้ำ',        days: 0 },
  { value: 'monthly',   label: 'ทุก 1 เดือน',   days: 30 },
  { value: 'quarterly', label: 'ทุก 3 เดือน',   days: 90 },
  { value: 'biannual',  label: 'ทุก 6 เดือน',   days: 182 },
  { value: 'annual',    label: 'ทุกปี',          days: 365 },
];

// Auto-create next occurrence on complete:
const handleComplete = (id: number) => {
  const rec = items.find(r => r.id === id);
  let updated = items.map(r => r.id === id ? { ...r, status: 'completed' } : r);
  if (rec?.recurrence && rec.recurrence !== 'none') {
    const opt = RECURRENCE_OPTIONS.find(o => o.value === rec.recurrence);
    if (opt?.days) {
      const nextDate = new Date(rec.dueDate);
      nextDate.setDate(nextDate.getDate() + opt.days);
      updated = [{ ...rec, id: Date.now(), status: 'upcoming', dueDate: nextDate.toISOString().slice(0, 10) }, ...updated];
    }
  }
  setItems(updated);
};
```

### 21.7 API Documentation Page Structure
Used in: ApiDocsPage

```
Page route: /app/api-docs
Nav: Settings group → "เอกสาร API" with Code2 icon
Target audience: Pro tier users building integrations

Required sections:
  1. Auth info card (base URL + session cookie explanation)
  2. Quick-start code snippet (tabs: JavaScript | curl | Python)
  3. Endpoint reference table (method badge + path + description)
  4. Link to full external docs (Traccar API reference)

Code snippet tab style:
  - Active tab: brand blue bg, white text
  - Inactive: surface-2 bg, ink-3 text
  - Code block: dark bg (#1E1E2E), mono font, 0.75rem
  - Copy button: top-right of code block
```

---

## 22. Implemented Patterns v3.1 — Session 2026-07-04 (100/100 Sprint)

### 22.1 Alert Row with Hover Actions
Used in: AlertsPage

```tsx
// Alert row shows action buttons (map view + dismiss) on hover only
// Prevents visual clutter — actions appear only when needed
<div onMouseEnter={() => setHovered(true)} onMouseLeave={() => setHovered(false)}>
  {/* Data columns */}
  ...
  {/* Actions — opacity-0 when not hovered, opacity-100 on hover */}
  <div className={`flex gap-1 transition-opacity ${hovered ? 'opacity-100' : 'opacity-0'}`}>
    <button onClick={() => navigate(`/app/map?vehicle=${deviceId}`)} title="ดูบนแผนที่">
      <MapPin size={13} />
    </button>
    <button onClick={() => onDismiss(id)} title="ยกเลิก">
      <X size={13} />
    </button>
  </div>
</div>
```

### 22.2 Undo Dismiss with Toast
Used in: AlertsPage

```tsx
// 3-second undo window via toast — best UX for reversible destructive actions
const handleDismissWithUndo = (id: number) => {
  setDismissed(prev => new Set([...prev, id]));
  toast.success('ยกเลิกการแจ้งเตือนแล้ว', {
    action: {
      label: 'เลิกทำ',
      onClick: () => setDismissed(prev => {
        const next = new Set(prev);
        next.delete(id);
        return next;
      }),
    },
    duration: 3000,
  });
};
```

### 22.3 Input Classes — Pure Tailwind (no JS DOM)
Used in: LoginPage

```tsx
// Replace inline styles + focusOn/focusOff JS DOM manipulation with this:
const inputCls = [
  'w-full px-4 py-3 text-sm rounded-xl',
  'border border-[#DADCE0] bg-white text-[#202124]',
  'outline-none transition-all duration-150',
  'focus:border-[#1A73E8] focus:ring-2 focus:ring-[#1A73E8]/20',
  'disabled:opacity-50 disabled:cursor-not-allowed',
].join(' ');

// Usage:
<input className={inputCls} {...register('email')} type="email" />
```

### 22.4 Role Permissions Reference Table
Used in: TeamPage

```tsx
// Collapsible permissions reference — toggle with useState
// Shows each action × each role as a quick reference for admins
function RolePermissionsTable() {
  const [open, setOpen] = useState(false);
  const PERMS = [
    { action: 'ดูแผนที่สด',    admin: true,  user: true  },
    { action: 'เพิ่มยานพาหนะ', admin: true,  user: false },
    // ...
  ];
  return (
    <div className="card mt-6 overflow-hidden">
      <button onClick={() => setOpen(o => !o)}>
        🔐 สิทธิ์การใช้งานตามบทบาท {open ? '▲' : '▼'}
      </button>
      {open && (
        <table className="w-full data-table">
          {PERMS.map(p => (
            <tr key={p.action}>
              <td>{p.action}</td>
              <td>{p.admin ? '✅' : '—'}</td>
              <td>{p.user ? '✅' : '❌'}</td>
            </tr>
          ))}
        </table>
      )}
    </div>
  );
}
```

### 22.5 Multi-Step Wizard Pattern
Used in: LineNotifySection, DLTPage

```tsx
// Step indicator + content shown conditionally per step
// Steps are numbered 1-based, clickable to navigate back

const [step, setStep] = useState<1|2|3>(1);

// Step indicator
<div className="flex items-center gap-2">
  {STEPS.map(({ n, label }) => (
    <div key={n} className="flex items-center gap-1.5">
      {n > 1 && <div className="w-6 h-px bg-border" />}
      <button onClick={() => setStep(n)} className="flex items-center gap-1.5 text-xs">
        <span className="w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold"
          style={{ background: step > n ? '#34A853' : step === n ? 'var(--brand)' : 'var(--surface-2)',
                   color: step >= n ? '#fff' : 'var(--ink-4)' }}>
          {step > n ? '✓' : n}
        </span>
        <span style={{ color: step === n ? 'var(--brand)' : step > n ? '#34A853' : 'var(--ink-4)' }}>
          {label}
        </span>
      </button>
    </div>
  ))}
</div>

// Content
{step === 1 && <Step1Content onNext={() => setStep(2)} />}
{step === 2 && <Step2Content onNext={() => setStep(3)} />}
{step === 3 && <Step3Content />}
```

### 22.6 Test Connection Pattern
Used in: DLTPage, LINE Notify

```tsx
// Standard test connection UX:
// - Show loading spinner during test (max2s simulated)
// - Toast success with timestamp
// - Persist last tested time in localStorage

function TestConnectionButton({ storageKey }: { storageKey: string }) {
  const [testing, setTesting] = useState(false);
  const [lastTested, setLastTested] = useState(
    () => localStorage.getItem(storageKey) ?? ''
  );
  const handleTest = async () => {
    setTesting(true);
    await new Promise(r => setTimeout(r, 2000)); // replace with real API call
    const now = new Date().toLocaleTimeString('th-TH');
    localStorage.setItem(storageKey, now);
    setLastTested(now);
    setTesting(false);
    toast.success(`เชื่อมต่อสำเร็จ (${now})`);
  };
  return (
    <div className="flex items-center gap-3">
      <button onClick={handleTest} disabled={testing} className="btn btn-secondary text-xs gap-1.5">
        {testing ? <Loader2 size={12} className="animate-spin" /> : <Activity size={12} />}
        {testing ? 'กำลังทดสอบ...' : 'ทดสอบการเชื่อมต่อ'}
      </button>
      {lastTested && (
        <span className="text-xs" style={{ color: 'var(--ink-4)' }}>
          ทดสอบล่าสุด: {lastTested}
        </span>
      )}
    </div>
  );
}
```

### 22.7 Follow Selected Vehicle (Live Map)
Used in: LiveMapPage

```tsx
// "Follow Selected" — keeps map centered on selected vehicle as it moves
// Implemented via MapController that reacts to position coordinate changes

const [followMode, setFollowMode] = useState(false);

// In MapController:
useEffect(() => {
  if (followMode && selected?.position) {
    map.panTo([selected.position.latitude, selected.position.longitude],
      { animate: true, duration: 0.3 });
  }
}, [followMode, selected?.position?.latitude, selected?.position?.longitude, map]);

// Toggle button (appears above selected vehicle panel):
<button
  onClick={() => setFollowMode(f => !f)}
  className="flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold"
  style={{
    background: followMode ? 'var(--brand)' : 'var(--surface-0)',
    color: followMode ? '#fff' : 'var(--ink-2)',
  }}
>
  {followMode ? '📍 ติดตามอยู่' : '🔓 ติดตาม'}
</button>

// IMPORTANT: clear followMode when vehicle is deselected
onClose={() => { setSelected(null); setFollowMode(false); }}
```

### 22.8 Device Attribute Sensor Display
Used in: FuelPage

```tsx
// Show real-time sensor data from GPS device position.attributes
// Only renders if ANY device has the attribute — otherwise hidden

function FuelSensorSection() {
  const { data: vehicles = [] } = useVehiclesWithPositions();
  const withFuel = vehicles.filter(v =>
    v.position?.attributes?.fuel !== undefined
  );
  if (withFuel.length === 0) return null; // hidden when no sensor data

  return (
    <div className="fill-block-elevated mt-5">
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
        {withFuel.map(v => {
          const pct = Math.min(100, Math.max(0, Math.round(v.position!.attributes!.fuel as number)));
          const color = pct < 20 ? '#EA4335' : pct < 40 ? '#FBBC04' : '#34A853';
          return (
            <div key={v.id} className="card p-3">
              <p className="num text-2xl font-bold" style={{ color }}>{pct}%</p>
              <p className="text-xs" style={{ color: 'var(--ink-4)' }}>{v.name}</p>
              {/* Progress bar */}
              <div className="w-full rounded-full h-1.5 mt-2" style={{ background: 'var(--surface-2)' }}>
                <div style={{ width: `${pct}%`, background: color }} className="h-full rounded-full" />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
// Pattern: use this for any position.attributes field (rpm, battery, temperature etc.)
```

```tsx
// Standard test connection UX:
// - Show loading spinner during test (max2s simulated)
// - Toast success with timestamp
// - Persist last tested time in localStorage

function TestConnectionButton({ storageKey }: { storageKey: string }) {
  const [testing, setTesting] = useState(false);
  const [lastTested, setLastTested] = useState(
    () => localStorage.getItem(storageKey) ?? ''
  );
  const handleTest = async () => {
    setTesting(true);
    await new Promise(r => setTimeout(r, 2000)); // replace with real API call
    const now = new Date().toLocaleTimeString('th-TH');
    localStorage.setItem(storageKey, now);
    setLastTested(now);
    setTesting(false);
    toast.success(`เชื่อมต่อสำเร็จ (${now})`);
  };
  return (
    <div className="flex items-center gap-3">
      <button onClick={handleTest} disabled={testing} className="btn btn-secondary text-xs gap-1.5">
        {testing ? <Loader2 size={12} className="animate-spin" /> : <Activity size={12} />}
        {testing ? 'กำลังทดสอบ...' : 'ทดสอบการเชื่อมต่อ'}
      </button>
      {lastTested && (
        <span className="text-xs" style={{ color: 'var(--ink-4)' }}>
          ทดสอบล่าสุด: {lastTested}
        </span>
      )}
    </div>
  );
}
```
