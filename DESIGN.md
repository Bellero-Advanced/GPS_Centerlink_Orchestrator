# DESIGN.md — GPS Global Tracker Design System
> Version 3.0 · Last updated: 2026-07-04
> **Product Name**: GPS Global Tracker (กรุณาใช้ชื่อนี้สม่ำเสมอ — ไม่ใช่ "Bellerox GPS")
> **Identity**: Signal · Precision · Command
> **Stack**: Google palette · IBM Plex Sans Thai · JetBrains Mono
>
> **AUDIT NOTE v3.0** — Updated from professional UX/UI audit (2026-07-04).
> Score before: 74/100. Target after implementing guidelines: 88/100.
> Key additions: Brand CI enforcement, Integration UX patterns, Error state specs,
> Onboarding patterns, Mobile-first rules, Performance perception guidelines.

---

## 1. Brand Identity — "Signal"

### Concept
Bellerox GPS is a **command center for fleets**, not a dashboard. Every screen should feel like the operator has the entire fleet's pulse in their hands. The design language is built around one metaphor: **a GPS signal — precise, reliable, always live.**

### The Three Brand Pillars

| Pillar | Meaning | How it Shows |
|--------|---------|--------------|
| **Signal** | Always connected, always live | Accent dots, pulse-free solid status colors, live WebSocket indicators |
| **Precision** | Exact data, no rounding, no approximation | Monospace numbers everywhere, 6-decimal coordinates, exact timestamps |
| **Command** | The operator is in control | Dense information layout, quick-action buttons, keyboard shortcuts |

### Brand Voice (UI copy)
- Thai-first, direct, no filler words
- Numbers without approximation: "67 km/h" not "about 70"
- Status with certainty: "ออนไลน์" not "ดูเหมือนจะออนไลน์"
- Actions as commands: "ส่งคำสั่ง" "ดูเส้นทาง" not "Click here to view route"

### Signature Visual Elements

**1. The Accent Bar** — The defining element of the Bellerox GPS brand.
Every navigation group, every section card, every status block gets a 3px left border strip in its semantic color. This is not decoration — it communicates hierarchy and category instantly.

```
┃ Core (Blue #1A73E8)  — Tracking, Map, Live
┃ Ops (Green #34A853)  — Fleet, Drivers, Dispatch
┃ Manage (Gray #9AA0A6) — Reports, Settings, Admin
```

**2. The Signal Dot** — A filled circle used for all vehicle/connection status.
- Size 8px in tables, 10px in cards, 12px in hero contexts
- Never animated (animation wastes rendering budget and implies uncertainty)
- Always paired with a text label (color alone never conveys meaning)

**3. Monospace Data** — Any number that changes is monospace.
Speed, distance, coordinates, timestamps, counts. This prevents layout shift when real-time data updates.

**4. Section Labels** — Caps, 11px, 0.08em tracking, ink-3.
Used above every group of related inputs/fields. Creates visual rhythm and scanability.

---

## 2. Color System — Google Palette

### Primary Palette
Derived from Google Maps' visual language — trusted, clear, globally recognizable.
Applied with the Bellerox GPS "Signal" identity: higher contrast, denser use.

```css
/* ── Brand (Google Blue) ─────────────────────────── */
--brand:         #1A73E8;   /* primary actions, active nav, focus rings */
--brand-700:     #1557B0;   /* hover/pressed state */
--brand-light:   #E8F0FE;   /* selected bg, brand tints */
--brand-ring:    rgba(26,115,232,0.20);  /* focus ring */

/* ── Surface ─────────────────────────────────────── */
--surface-0:     #FFFFFF;   /* cards, modals, panels */
--surface-1:     #F8F9FA;   /* page background */
--surface-2:     #F1F3F4;   /* sidebar, table headers, subtle areas */
--surface-3:     #E8EAED;   /* dividers, pressed states */

/* ── Text ────────────────────────────────────────── */
--ink-1:         #202124;   /* primary text */
--ink-2:         #3C4043;   /* secondary text */
--ink-3:         #5F6368;   /* labels, captions, section headers */
--ink-4:         #9AA0A6;   /* placeholders, disabled, muted */

/* ── Border ──────────────────────────────────────── */
--border:        #DADCE0;   /* standard dividers, card borders */
--border-dark:   #BDC1C6;   /* emphasized borders, active frames */

/* ── Dark Mode ────────────────────────────────────── */
.dark {
  --brand:         #8AB4F8;
  --brand-700:     #669DF6;
  --brand-light:   #1A2746;
  --brand-ring:    rgba(138,180,248,0.20);

  --surface-0:     #202124;
  --surface-1:     #171717;
  --surface-2:     #292A2D;
  --surface-3:     #3C4043;

  --ink-1:         #E8EAED;
  --ink-2:         #BDC1C6;
  --ink-3:         #9AA0A6;
  --ink-4:         #5F6368;

  --border:        #3C4043;
  --border-dark:   #5F6368;
}
```

### Semantic / Status Colors — IMMUTABLE
These are fixed. Users internalize them. Changing them breaks operator trust.

```css
/* Vehicle Status */
--moving:   #34A853;   /* Google Green — vehicle in motion */
--idle:     #FBBC04;   /* Google Yellow — engine on, parked */
--stopped:  #9AA0A6;   /* Neutral Gray — engine off */
--offline:  #EA4335;   /* Google Red — signal lost */
--towing:   #FA7B17;   /* Google Orange — moving without ignition */

/* Alert Severity */
--critical: #EA4335;
--warning:  #FBBC04;
--info:     #1A73E8;
--success:  #34A853;
```

### Section Accent Colors
Each navigation group uses a fixed accent color for its sidebar bar and section borders.
```css
--accent-core:    #1A73E8;  /* Brand Blue — Live Map, Dashboard, Trip Replay */
--accent-ops:     #34A853;  /* Brand Green — Fleet, Drivers, Geofences */
--accent-report:  #FA7B17;  /* Brand Orange — Reports, Analytics, Scoring */
--accent-manage:  #9AA0A6;  /* Neutral — Settings, Team, Admin */
```

### Map Colors
```css
--map-route:             #1A73E8;       /* Route line */
--map-route-history:     #9AA0A6;       /* Historical route (muted) */
--map-geofence-fill:     rgba(234,67,53,0.08);
--map-geofence-border:   #EA4335;
--map-selected-ring:     #1A73E8;
```

---

## 3. Typography

### Font Stack
```
Primary (UI + Thai text): "IBM Plex Sans Thai", system-ui, sans-serif
Data / Coordinates / IDs: "JetBrains Mono", monospace

NOTE: Inter, Sarabun, Calistoga are REMOVED — do not re-add them.
IBM Plex Sans Thai covers both Latin and Thai scripts in one weight.
```

### Type Scale (4px baseline)
```
11px / 1.4lh  — Section labels (UPPERCASE, 600, +0.08em tracking)
12px / 1.4lh  — Badges, captions, table footnotes
13px / 1.5lh  — Table cells, secondary body, compact list items
14px / 1.5lh  — Default body text, form labels
16px / 1.4lh  — Card titles, modal headings
18px / 1.3lh  — Section headings
22px / 1.2lh  — Page titles
```

### Rules
- **Page title**: 22px, weight 700, IBM Plex Sans Thai, letter-spacing -0.01em
- **Section label**: 11px, weight 600, UPPERCASE, letter-spacing +0.08em, ink-3
- **Data numbers** (speed, distance, coordinates): JetBrains Mono, tabular-nums — prevents layout shift on live updates
- **Thai text**: IBM Plex Sans Thai, minimum 13px, never truncate mid-syllable
- **Currency**: ฿ prefix, comma separators: `฿1,234.50`

---

## 4. Spacing & Layout

### Spacing Scale (4px base)
```
2px  → icon-to-text gaps within a single element
4px  → between tightly coupled inline elements
8px  → between related items in a group
12px → compact padding (badges, chips, table cells)
16px → standard padding — form rows, list items, card sections
20px → between card sections
24px → card padding (horizontal)
28px → between cards
32px → page horizontal padding
40px → between major page sections
```

### Layout Dimensions
```
Sidebar expanded:  224px
Sidebar collapsed: 52px (icon + tooltip flyout)
Content max-width: 1024px (form/table/settings pages)
Map page:          sidebar 288px + full-height map fill
Modal max-width:   480px (standard), 640px (complex forms)
```

### Border Radius
```
2px  → Status dots, tiny badges
4px  → Compact chips, table-internal elements
6px  → Inputs, dropdowns, small buttons
8px  → Cards, panels, standard buttons
12px → Modals, large panels
16px → Feature cards, full-section containers
```

---

## 5. Component Specifications

### 5.1 Sidebar Navigation
```
Width: 224px expanded, 52px collapsed
Background: var(--surface-2)
Border-right: 1px solid var(--border)

Nav item:
  Padding: 6px 8px
  Border-radius: 6px
  Icon: 16px, ink-3
  Label: 13px, weight 400, ink-2
  Active: background brand-light, icon+label color brand
  Hover: background surface-3, no transition delay

Accent bar (per nav group):
  .nav-group::before { width: 3px; height: 12px; border-radius: 999px; }
  Core group → #1A73E8
  Ops group → #34A853
  Manage group → #9AA0A6

Collapsed mode:
  Show only 16px icon, centered
  Hover → tooltip flyout: white card, shadow-md, zIndex 1000
```

### 5.2 Vehicle Status Dot
```css
.status-dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  display: inline-block;
  flex-shrink: 0;
}
/* Sizes: 8px (table), 10px (card), 12px (hero) */
/* Never animate — solid color only */
```

### 5.3 Status Badge (pill)
```
Padding: 2px 8px
Border-radius: 999px
Font: 11px, weight 600
Background: status color at 10% opacity
Text color: status color at 100%
Border: none
```

### 5.4 KPI Card
```
Layout: 3 or 4 columns, equal width
Padding: 20px 24px
Header: icon (20px, colored) + label (11px section-label)
Value: 28px, JetBrains Mono, weight 700, ink-1
Subtitle: 12px, ink-3 (optional delta or context)
Border: 1px solid border
Border-radius: 8px
Left accent: 3px solid corresponding section accent color
```

### 5.5 Cards
```css
.card {
  background: var(--surface-0);
  border: 1px solid var(--border);
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}
.card:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.09); }
/* Transition: box-shadow 120ms ease — ONLY this property */
```

### 5.6 Buttons
```css
/* Primary */
.btn-primary {
  background: var(--brand);
  color: #fff;
  padding: 7px 14px;
  border-radius: 6px;
  font-size: 13px; font-weight: 500;
  border: none;
}
.btn-primary:hover { background: var(--brand-700); }

/* Secondary */
.btn-secondary {
  background: var(--surface-2);
  border: 1px solid var(--border);
  color: var(--ink-2);
  /* same padding/radius as primary */
}

/* Destructive */
.btn-danger {
  background: rgba(234,67,53,0.08);
  border: 1px solid rgba(234,67,53,0.30);
  color: var(--critical);
}

/* NO box-shadow on buttons, NO transform on click */
```

### 5.7 Inputs
```css
.input {
  background: var(--surface-1);
  border: 1px solid var(--border);
  border-radius: 6px;
  padding: 8px 12px;
  font-size: 14px;
  color: var(--ink-1);
}
.input:focus {
  border-color: var(--brand);
  box-shadow: 0 0 0 3px var(--brand-ring);
  outline: none;
}
.input.error { border-color: var(--critical); }
```

### 5.8 Tables
```
Header: background surface-2, text 11px UPPERCASE ink-3 weight 600
Row border: 1px solid border between rows only (no outer table border)
Row hover: background surface-1
Cell padding: 10px 16px
Numeric cells: JetBrains Mono, text-right
First column: font-medium ink-1 (vehicle name, user name)
Action cell: right-aligned icon buttons, visible on row hover only
```

### 5.9 Modal
```
Overlay: rgba(0,0,0,0.40) — instant, no fade
Panel: surface-0, border-radius 12px, box-shadow 0 8px 32px rgba(0,0,0,0.18)
Header: title 16px weight 600 + close button (top-right)
Body: px-6 py-5
Footer: flex justify-end gap-2, pt-4 border-top
Max-width: 480px centered
NO slide/fade animation — instant open/close
```

### 5.10 Map Markers (Leaflet divIcon)
```
Shape: Filled circle (not pin — circles don't obscure the coordinate)
Normal: 26px, status color fill, 2px white border
Selected: 34px, status color fill, 3px white border + 2px brand ring
Hover: scale 1.1 (ONLY allowed transform — brief feedback)
Direction arrow: thin triangle indicator at top edge, rotates with course
Font: JetBrains Mono for speed overlay if shown

HTML template:
<div style="
  width:26px; height:26px; border-radius:50%;
  background: {statusColor};
  border: 2.5px solid white;
  box-shadow: 0 1px 4px rgba(0,0,0,0.3);
">
  <div class="course-arrow" style="transform: rotate({course}deg);">▲</div>
</div>
```

### 5.11 Map Popup
```
Width: 220px
Padding: 12px 14px
Border-radius: 8px
Shadow: 0 4px 16px rgba(0,0,0,0.15)

Layout:
  Row 1: Vehicle name (14px, weight 600) + status badge
  Divider
  Row 2: speed (mono) + course icon
  Row 3: address (13px, truncated, 2 lines max)
  Row 4: "Updated X seconds ago" (11px, ink-4)
  Divider
  Footer: "ดูรายละเอียด" + "ประวัติเส้นทาง" (compact ghost buttons)
```

---

## 6. Page Design Specifications

### 6.1 Login Page
```
Layout: Fullscreen, centered single card on dark map-like background
Card: max-width 380px, surface-0, border-radius 16px, strong shadow
Logo: top-center of card, height 32px
Title: 18px, weight 600 (Thai: "เข้าสู่ระบบ")
Fields: email + password, color-fill (surface-1 bg, no border) style
CTA: Full-width brand-color button
Footer: Forgot password link, Register link (if server.registration = true)
Background: dark gradient or static map image — reinforces GPS context
```

### 6.2 Dashboard
```
Above fold (no scroll required on 1080p):
  Row 1: 4 KPI cards — Total, Online, Moving, Offline
  Row 2: 50-row vehicle status table (most critical fleet view)

KPI cards use section accent colors (core = blue, moving = green)
Table: sortable by status, name, last update
"Live" indicator: solid green dot + "Live" text, top-right of table header
No charts on first load — charts are below the fold (analytics page)
```

### 6.3 Live Map (most used page)
```
Layout: Left panel 288px + right map fills remaining viewport (full height)
Left panel:
  Search input (full width, with clear button)
  Status filter row: All / Moving / Idle / Stopped / Offline chips
  Vehicle list (virtualized, 44px row height)
    Row: status dot + name + speed + "Xm ago"
  Footer: vehicle count + filter result count

Map right:
  No decorative elements
  Markers only (clustered at > 200 vehicles)
  Layer switcher top-right: Map | Satellite | Traffic
  "ดูทั้งหมด" (fit bounds) button
  
Selected vehicle: bottom-center floating card (240px wide)
  Name + status + speed + address + action buttons
```

### 6.4 Fleet Management
```
Header: title + device count badge + "เพิ่มยานพาหนะ" button
Search + group filter
Table: Name | IMEI | Protocol | Status | Last Seen | Actions
Row hover → shows Edit / Commands / Delete icon buttons
Bulk select: checkbox column, bulk delete/group assign
Empty state: centered illustration + CTA
```

### 6.5 Settings Page
```
Layout: Single scrollable column, max-width 720px, centered
Sections (in order):
  1. Theme — light/dark/system toggle cards
  2. Server Settings (admin only) — Traccar /api/server config
  3. LINE Notify — global + per-group tokens
  4. DLT GPS Web Service — Thai government compliance
  5. Alert Rules — toggle individual alert types
  6. Danger Zone (admin only) — reset, wipe data

Each section is a card with:
  - 3px left accent bar matching section type
  - Section header (icon + title + optional badge)
  - Content
```

### 6.6 Team (User Management)
```
Admin only — show 403 empty state for non-admins
Header: "ทีมและสมาชิก" + "เชิญสมาชิก" button
Table: Avatar | Name | Email | Role | Device Limit | Expiry | Actions
Actions: Edit (role/limits) + Delete (with confirm)
Invite modal: name + email + password + admin toggle
Edit modal: name + email + role + deviceLimit + expirationTime
```

---

## 7. Motion & Animation Rules

### Allowed
```
Duration: 100-150ms max for state changes
Properties: opacity, background-color, border-color, box-shadow, color
Timing: ease-out or linear only
Exception: map flyTo is 300ms (Leaflet built-in, can't shorten)
```

### Prohibited
```
transform: translate/scale/rotate on transitions (layout recalc)
height/width transitions (causes reflow)
Page-level slide-in effects
Pulse/ping on status dots
Skeleton shimmer longer than 300ms
CSS @keyframes on live data elements
```

### Loading States
```
Initial page load: opacity 0→1 fade 150ms, once only
Data refresh: update in-place, no transition
Error: instant
Skeleton: static (no shimmer), surface-2 blocks, 150ms fade out when data arrives
```

---

## 8. Performance Rules

### React Query intervals (match engineering-standards.md)
```typescript
positions: { refetchInterval: 10_000, staleTime: 5_000 }
devices:   { refetchInterval: 30_000, staleTime: 20_000 }
reports:   { refetchInterval: false,  staleTime: 300_000 }
events:    { refetchInterval: 30_000 }
```

### Map Rendering Thresholds
```
< 100 vehicles:  standard Leaflet divIcon markers
100–500:         react-leaflet-cluster
> 500:           canvas rendering or viewport filter
Rule: never render > 200 visible markers simultaneously
```

### Bundle Rules
```
No new UI libraries beyond: React, Tailwind, Lucide, Leaflet, Recharts
Lazy-load all pages (React.lazy + Suspense already in place)
Images: WebP, max 200KB for any decorative asset
Icons: Lucide only — no icon fonts, no SVG sprites
```

---

## 9. Accessibility

- Touch targets: minimum 44×44px for all interactive elements
- Color alone never conveys status — always paired with label or icon
- Form inputs: always have associated `<label>` elements
- Focus rings: styled to brand color, never removed (`outline: none` only when custom ring applied)
- WCAG AA contrast for all text/background combinations
- `prefers-reduced-motion`: skip all transitions when enabled

---

## 10. Thai Language Rules

- **Font**: IBM Plex Sans Thai — minimum 13px (Thai script needs size to be legible)
- **Truncation**: Use `overflow: hidden` only on containers — never cut Thai mid-syllable with `…`
- **Date/time**: Thai locale (`th-TH`), 24h format, Buddhist Era optional in settings
- **Currency**: ฿ prefix, comma separators: `฿1,234.50`
- **Numbers in UI**: Always Arabic numerals — never Thai numerals (ก, ข, ค) in data displays

---

## 11. Dark Mode Guidelines

Dark mode is **equal priority** — fleet managers work 24/7, truck dispatch is often at night.
Dark mode is not "inverted light mode" — it has its own logic.

```
Background hierarchy in dark:
  Page bg:     #171717  (deepest)
  Card/panel:  #202124  (lifted)
  Input/subtle: #292A2D (elevated)
  Border:      #3C4043  (subtle separator)

Status colors stay the same (green/amber/red — must pop on dark)
Brand blue shifts to #8AB4F8 (lighter for dark backgrounds)
```

---

## 12. Component Variants by Usage Frequency

**High-frequency (live map, dashboard) — performance critical:**
- Minimize re-renders: memo markers, patch-only position updates
- No console.log in production paths
- Batch React Query updates from WebSocket

**Medium-frequency (fleet list, alerts, reports):**
- Standard React Query staleTime
- Virtualize lists > 100 items (react-window or @tanstack/virtual)

**Low-frequency (settings, team, admin):**
- Full skeleton loading acceptable
- No need to optimize re-renders

---

## 13. Brand CI — Enforcement Rules (v3.0)

### 13.1 Product Name
```
Correct:   "GPS Global Tracker"
Incorrect: "Bellerox GPS", "GPS TMS", "Tracker App"

Use in:
  - Page titles: "GPS Global Tracker — แผนที่สด"
  - Login card header
  - Email report subjects: "รายงาน GPS Global Tracker"
  - Error pages
  - Browser tab: "GPS Global Tracker"
```

### 13.2 Logo Usage Rules
```
Available variants:
  <Logo variant="dark" />   → black logo on white/light bg (login card, reports)
  <Logo variant="light" />  → white logo on dark bg (sidebar, dark map overlay)
  <Logo markOnly />         → icon only for collapsed sidebar (must be ≥ 24px)

Minimum size: 24px height (icon), 80px height (full wordmark)
Clear space: minimum 8px on all sides
Never: stretch, recolor, add shadow, place on busy background without overlay
```

### 13.3 Voice & Tone — Extended
```
Context       Thai copy                          NOT this
──────────────────────────────────────────────────────────
Status        "ออนไลน์"                          "กำลังเชื่อมต่อ..."
Error         "เชื่อมต่อไม่ได้ — ลองอีกครั้ง"      "เกิดข้อผิดพลาด"
Success       "บันทึกแล้ว"                        "การดำเนินการเสร็จสมบูรณ์"
CTA           "ดูแผนที่"                          "คลิกที่นี่เพื่อดูแผนที่"
Delete        "ลบยานพาหนะ"                        "คุณแน่ใจหรือไม่?"
Empty state   "ยังไม่มียานพาหนะ — เพิ่มตัวแรก"   "ไม่พบข้อมูล"
```

### 13.4 Favicon & App Icon
```
Use the "mark only" version of the logo at:
  16×16: favicon
  32×32: favicon HD
  192×192: PWA icon (add to manifest.json)
  512×512: PWA splash icon
  
Background: --brand (#1A73E8) filled square, icon white
Border-radius for app icon: 22% of size (iOS-style)
```

---

## 14. Empty State Design System (v3.0)

Every page that can have zero data MUST implement this pattern.

### 14.1 Structure
```
[Icon — 48px, ink-4]
[Title — 16px, weight 600, ink-2]
[Subtitle — 14px, ink-3, max 2 lines]
[CTA button — brand primary, optional]
```

### 14.2 Copy Templates
```typescript
const EMPTY_STATES = {
  vehicles:    { title: 'ยังไม่มียานพาหนะ',     cta: 'เพิ่มยานพาหนะ' },
  alerts:      { title: 'ไม่มีการแจ้งเตือน',     cta: undefined },
  drivers:     { title: 'ยังไม่มีคนขับ',          cta: 'เพิ่มคนขับ' },
  geofences:   { title: 'ยังไม่มีโซน',            cta: 'วาดโซนใหม่' },
  reports:     { title: 'เลือกช่วงเวลาและกดค้นหา', cta: undefined },
  maintenance: { title: 'ไม่มีงานที่กำหนด',        cta: 'เพิ่มรายการ' },
  fuel:        { title: 'ยังไม่มีบันทึกเชื้อเพลิง', cta: 'เพิ่มบันทึก' },
  notifications: { title: 'อ่านหมดแล้ว ✓',       cta: undefined },
}
```

---

## 15. Error State Design System (v3.0)

### 15.1 Error Levels
```
Level 1 — Inline field error:
  Below input, 12px, --critical color, ← icon 12px
  Appear on blur (not on keystroke)

Level 2 — Toast notification:
  Top-right, max-width 320px, 4s auto-dismiss
  Error: red bg, Success: green bg, Warning: amber
  Always include: what happened + what to do

Level 3 — Section error (data fetch failed):
  Replace skeleton/data area with:
  [AlertTriangle icon, 32px, --warning]
  "โหลดข้อมูลไม่ได้" (14px)
  [ลองอีกครั้ง button]
  Never show raw API error messages to users

Level 4 — Full page error (auth/network):
  Centered card, icon 64px, title, description, action button
  Always offer a path back (Go to dashboard / Try again / Contact support)
```

### 15.2 Network Error Handling
```typescript
// Standard error message map — use these EXACT Thai strings
const ERROR_MESSAGES = {
  'ERR_NETWORK':      'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
  '401':              'เซสชั่นหมดอายุ — กรุณาเข้าสู่ระบบใหม่',
  '403':              'คุณไม่มีสิทธิ์เข้าถึงส่วนนี้',
  '404':              'ไม่พบข้อมูลที่ร้องขอ',
  '429':              'ส่งคำขอบ่อยเกินไป — รอสักครู่แล้วลองใหม่',
  '500':              'เซิร์ฟเวอร์มีปัญหา — ทีมงานได้รับแจ้งแล้ว',
  'timeout':          'การเชื่อมต่อใช้เวลานานเกินไป — ลองอีกครั้ง',
}
```

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
