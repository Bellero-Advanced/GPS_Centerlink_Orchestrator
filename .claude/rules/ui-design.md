# UI/UX Design System — Bellerox GPS
# World-class fleet management interface design

## Design Philosophy

**GPS tracking is a safety-critical, time-sensitive tool.**
Design for speed of comprehension, not aesthetics.
A fleet manager needs to find a vehicle in 2 seconds, not admire the interface.

Core principles:
1. **Information density > whitespace** — show more data, less decoration
2. **Color conveys meaning** — green=moving, amber=idle, red=offline/alert
3. **Map is primary** — the map fills 70% of screen on tracking pages
4. **Mobile-ready** — fleet managers are on tablets/phones, not desktops
5. **Thai-first** — Sarabun font, Thai numerals for amounts, date in Buddhist Era optionally

## Color System

```css
/* Vehicle Status Colors — NEVER change these, users internalize them */
--color-moving: #22c55e;      /* green-500 — vehicle moving */
--color-idle: #f59e0b;        /* amber-400 — engine on, stopped */
--color-stopped: #94a3b8;     /* slate-400 — engine off */
--color-offline: #ef4444;     /* red-400 — no signal */
--color-towing: #8b5cf6;      /* violet-500 — moving without ignition (alert!) */

/* Brand */
--color-brand: #1d7aed;       /* blue-600 — primary brand */
--color-brand-dark: #1661d9;  /* blue-700 */

/* Background hierarchy */
--bg-app: #f1f5f9;            /* slate-100 — page background */
--bg-canvas: #ffffff;         /* white — card/panel */
--bg-subtle: #f8fafc;         /* slate-50 — subtle section bg */

/* Text */
--text-primary: #0f172a;      /* slate-900 */
--text-secondary: #334155;    /* slate-700 */
--text-muted: #64748b;        /* slate-500 */
--text-placeholder: #94a3b8;  /* slate-400 */
```

## Typography

- **UI labels**: Inter (English) / Sarabun (Thai) — system font stack
- **Numbers/codes/coordinates**: JetBrains Mono (tabular-nums)
- **Vehicle names**: font-semibold, truncate long names
- **Speeds**: font-mono, tabular-nums — they change rapidly, must not reflow layout
- **Coordinates**: font-mono text-xs — always lat 6 decimal places

```tsx
// Numeric display pattern
<span className="font-mono tabular-nums text-slate-900 font-medium">
  {knotsToKmh(speed)} km/h
</span>
```

## Component Patterns

### Vehicle List Item
```
[status dot] [vehicle name] ............... [speed]
             [address (truncated)]         [status badge]
```

### Map Marker (divIcon)
- Circle shape (not pin — pins obscure position)
- Color = vehicle status
- Size: 28px normal, 36px when selected
- White border (2-3px) — shows on any map background
- Moving vehicles: subtle pulse animation

### KPI Card
```
[icon bg]
[big number, mono]
[label, muted]
[optional: subtitle]
```

### Alert Badge (always these variants)
```typescript
type AlertSeverity = 'critical' | 'warning' | 'info' | 'success';
// critical = red (speeding, geofence exit, towing)
// warning = amber (low fuel, idle too long)
// info = blue (geofence enter, trip started)
// success = green (trip ended normally)
```

## Page Layouts

### Live Map Page
```
[Vehicle Panel 288px] | [Map fullscreen]
  - Search            |   - Tile layer
  - Status filter     |   - Vehicle markers
  - Vehicle list      |   - Geofence overlays
                      |
                      | [Selected vehicle bar (bottom center)]
```

### List Pages (Fleet, Alerts, Reports)
```
[Page Header: title + action button]
[Search bar + filters]
[Data table with fixed headers, sticky first column]
[Pagination or infinite scroll for > 100 items]
```

### Detail Pages (Vehicle detail, Driver detail)
```
[Back button] [Vehicle name] [Status badge] [Action buttons]
[Tab bar: Overview / History / Trips / Alerts / Settings]
[Tab content]
```

### Dashboard Page
```
[KPI cards row: total vehicles, online, moving, offline]
[Charts row: vehicle status pie, trips today, distance today]
[Recent alerts table]
[Live vehicle list (30 items)]
```

## Map-Specific Design

### Tile Layers
- **Default**: OpenStreetMap (free, good global coverage)
- **Satellite**: Esri World Imagery (free for non-commercial)
- **Thai Enhanced**: Longdo Map (better Thai village/rural roads)
- **Traffic**: Google Maps or Longdo (paid)

### Layer Switcher
Always provide: Map | Satellite | Traffic toggle (3 buttons top-right of map)

### Map Controls
- Zoom in/out buttons (top-right)
- "Fit all vehicles" button (auto-zoom to show all vehicles)
- "Follow selected" toggle (keeps selected vehicle centered)
- Cluster toggle (group nearby markers vs show individual)

### Popup Design
```
[Vehicle Name]     [IMEI: xxxxx]
────────────────────────────────
⚡ 67 km/h         ↗ 245°
📍 Address (truncated)
🕒 Updated 5 seconds ago
────────────────────────────────
[View Details] [Track History]
```

## Mobile-Specific (Thai fleet managers on tablets)

### Breakpoints
- Mobile: 375-639px — single column, map full screen
- Tablet: 640-1023px — sidebar collapsible
- Desktop: 1024px+ — full two-column layout

### Touch Targets
- All tap targets: minimum 44×44px
- Bottom navigation for mobile (Dashboard, Map, Fleet, Alerts)
- Swipe gestures for vehicle list (swipe right to call driver, swipe left to track)

### Thai Users on Mobile
- Sarabun font required (Thai script clarity)
- Large text sizes for outdoor use (fleet managers in sun)
- High contrast mode for outdoor visibility

## Animation Guidelines

- **Duration**: 150-250ms (GPS data updates are frequent, animations must not lag)
- **Marker movement**: CSS transition on lat/lng changes → smooth vehicle gliding
- **Status changes**: Instant (no animation — safety info must appear immediately)
- **Panel transitions**: 250ms ease-out slide
- **Loading**: Skeleton screens, not spinners for main content
- **Reduce motion**: Respect `prefers-reduced-motion` always

## Dark Mode

- Fleet managers work at night (truck logistics is 24/7)
- Dark mode is mandatory, not optional
- Map: dark tile layer (CartoDB Dark Matter or Mapbox dark)
- Markers same colors (green/amber/red must pop on dark map)
- Implementation: Tailwind `dark:` variants + CSS var switch via `.dark` class

## Internationalization (i18n) Pattern

```typescript
// src/lib/i18n.ts
const translations = {
  th: {
    'vehicle.moving': 'กำลังเดินทาง',
    'vehicle.idle': 'จอดติดเครื่อง',
    'vehicle.stopped': 'จอดดับเครื่อง',
    'vehicle.offline': 'ออฟไลน์',
  },
  en: {
    'vehicle.moving': 'Moving',
    'vehicle.idle': 'Idling',
    'vehicle.stopped': 'Stopped',
    'vehicle.offline': 'Offline',
  },
  vi: { /* Vietnamese */ },
  id: { /* Indonesian */ },
};
```
Use `i18next` when adding APAC languages. Thai is primary, English is admin.
