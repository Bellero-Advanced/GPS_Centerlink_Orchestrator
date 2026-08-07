# GPS Global Tracker — Project Memory
> **Strategy**: Thai → APAC → Global · GPS SaaS Fleet Management
> **Last updated**: 2026-07-02 (Session 23 — Full Traccar integration + DESIGN.md v2 + Device Commands)

## Topic Files
- [GPS Domain Knowledge](.claude/rules/gps-domain-knowledge.md)
- [Product Strategy](.claude/rules/product-strategy.md)
- [Engineering Standards](.claude/rules/engineering-standards.md)
- [UI/UX Design System](.claude/rules/ui-design.md)
- [Infrastructure](.claude/rules/infrastructure.md)
- [Session Continuity](.claude/rules/session-continuity.md)

---

## Current State

**Brand**: GPS Global Tracker (logo: `public/logo.png` — black PNG, invert for dark bg)
**Version**: web app commit `5ef6651` deployed at `https://12339ea6.bellerox-gps.pages.dev`
**Stack**: Vite 5 + React 18 + TypeScript strict + Tailwind + Leaflet + Traccar 6.14.5

### GitHub Repos
| Repo | URL | Branch |
|------|-----|--------|
| `bellerox-gps-web` | https://github.com/MNupakorn/bellerox-gps-web | main |
| `bellerox-gps-mobile` | https://github.com/MNupakorn/bellerox-gps-mobile | main |
| `bellerox-gps-infra` | https://github.com/MNupakorn/bellerox-gps-infra | main |

### Cloudflare Deployment
| URL | Status |
|-----|--------|
| `https://bellerox-gps.pages.dev` | ✅ Live (CI via wrangler-action@v3) |
| `https://gps.bellerox.com` | ⏳ DNS CNAME pending (CF dashboard) |
| `api.gps.bellerox.com` | ✅ Worker + Custom Domain deployed |
| `traccar.gps.bellerox.com` | ⚠️ DNS A record needs update → `34.142.244.40` |

### GCP Infrastructure (Production-Ready ~$54/month)
| Resource | Current Config | Notes |
|----------|---------------|-------|
| VM | `n2-standard-2` (2vCPU/8GB) | Upgraded 2026-08-01 |
| Static IP | `34.142.244.40` (reserved) | Won't change on restart |
| Disk | ~50GB HDD | |
| PostgreSQL 16 | Docker on VM (shared_buffers 1GB) | 10 indexes + 2 materialized views |
| PgBouncer | Docker on VM (transaction pool) | NEW: connection pooling |
| Redis 7 | Docker on VM (128MB LRU) | |
| Nginx | HTTP/2 + API cache + rate limiting | |
| Cost | ~$54/month (~฿1,940) | n2-standard-2 + storage + egress |

### ⚠️ DNS Pending (Manual Action Needed)
Update `traccar.gps.bellerox.com` in Cloudflare dashboard:
- Zone: `bellerox.com`
- Record: `traccar.gps` (A, NOT proxied)
- Change: `34.143.247.131` → `34.142.244.40`
- Dashboard: https://dash.cloudflare.com/24f5fdf5624419bcfecc441609b0b75c/bellerox.com/dns/records

**Until fixed**: The CF Worker at `api.gps.bellerox.com` cannot reach Traccar (502 error)

---

## Design System (Google-inspired, color-fill)

### Colors (Google palette — never change)
```
Brand:   #1A73E8  (Google Blue)
Green:   #34A853  (Moving / Success)
Red:     #EA4335  (Offline / Error)
Yellow:  #FBBC04  (Idle / Warning)
Orange:  #FA7B17  (Towing)
Muted:   #9AA0A6  (text-muted, Stopped)
Text:    #5F6368  (secondary text)
```

### Typography
- **UI**: IBM Plex Sans Thai — single font for both Latin + Thai scripts
- **Numbers**: JetBrains Mono
- **Inter / Sarabun / Calistoga**: REMOVED — do not re-add

### Input / Form Design (color-fill, no borders)
```css
/* All .input, .notion-input, .select, .textarea */
background: var(--surface-2);   /* no border */
border-radius: 6px;
focus: background var(--surface-3) + ring 2px var(--brand-ring)
```

### Nav Group Chip Style (accent-line minimal, no pill background)
```css
.nav-group-chip { background: transparent; }
.nav-group-chip::before { width:3px; height:12px; border-radius:999px; }
.nav-chip-core::before  { background: #1A73E8; }
.nav-chip-ops::before   { background: #34A853; }
.nav-chip-manage::before { background: #9AA0A6; }
```

### Sidebar
- Accordion collapse by group
- collapsed → RailGroup with hover flyout (fixed overlay, zIndex 1000)
- Header: `<Logo markOnly={isCollapsed} />`

---

## Key Components

### `src/components/SearchSelect.tsx`
Searchable dropdown — use for ALL vehicle/device pickers.
```typescript
<SearchSelect
  options={devices.map(d => ({ value: String(d.id), label: d.name, subtitle: d.uniqueId }))}
  value={deviceId ? String(deviceId) : undefined}
  onChange={v => setDeviceId(Number(v))}
  placeholder="— เลือกยานพาหนะ —"
  searchPlaceholder="ค้นหาชื่อ หรือ IMEI..."
/>
```
Props: `options`, `value?:string`, `onChange`, `placeholder?`, `searchPlaceholder?`, `label?`, `disabled?`, `emptyText?`

### `src/components/Logo.tsx`
```typescript
<Logo height={28} variant="dark" />   // black logo on white bg
<Logo height={28} variant="light" />  // white logo on dark bg (via CSS invert)
<Logo markOnly />                     // icon-only for collapsed sidebar
```

### `src/hooks/useTraccarWebSocket.ts`
Circuit breaker: MAX_RECONNECT_RETRIES=5, exponential backoff 2s→30s.
Status: `'connecting' | 'connected' | 'disconnected' | 'failed'`
On 'failed' → App.tsx shows banner with retry button.

---

## Auth & API

**Auth**: Traccar Basic Auth, cookie-based (JSESSIONID, `withCredentials: true`)
- NO passwords in localStorage
- Auto-logout on 401 via Axios interceptor
- Login lockout after 5 attempts (30-min cooldown)
- Mobile devices blocked (MobileBlockPage)
- Forgot password flow (email-based via Traccar)

**API base**: `https://api.gps.bellerox.com` (Cloudflare Worker → Traccar)
**WebSocket**: `wss://api.gps.bellerox.com/api/socket`
- NEVER use `traccar-api.bellerox.com` or `traccar.gps.bellerox.com` in frontend

**Fix**: Traccar PUT /api/users/{id} requires FULL user object:
```typescript
updateUser(user.id, { ...user, name, email })  // ← always spread full object
```

---

## Data Persistence

| Domain | Storage | Notes |
|--------|---------|-------|
| Devices / Positions | Traccar API + React Query | Real-time via WebSocket |
| Drivers | Traccar `/api/drivers` API | Real CRUD |
| Fuel logs | `localStorage` key `bellerox-fuel-logs` | No Traccar table |
| Maintenance records | `localStorage` key `bellerox-maintenance-records` | No Traccar table |
| Notifications (read/dismiss) | `localStorage` | events from Traccar `/api/events` |
| Dispatch / POI / Inspection / Compliance / Predictive / Audit | `localStorage` | No Traccar tables |

---

## Pages Status

### Core (full Traccar API)
| Page | Route | Status |
|------|-------|--------|
| Login | `/login` | ✅ Google-style white card, video bg |
| Dashboard | `/app` | ✅ KPIs + charts + recent alerts |
| LiveMap | `/app/map` | ✅ Leaflet + WebSocket real-time |
| Fleet | `/app/fleet` | ✅ Device CRUD + detail |
| Geofences | `/app/geofences` | ✅ Leaflet draw |
| Reports | `/app/reports` | ✅ Trips + Summary + CSV |
| Alerts | `/app/alerts` | ✅ Real Traccar events |
| Drivers | `/app/drivers` | ✅ Real Traccar drivers API |
| Vehicle Detail | `/app/vehicles/:id` | ✅ History + trips |
| Trip Replay | `/app/replay` | ✅ Animated route playback |
| Account Settings | `/app/settings/account` | ✅ |
| Settings | `/app/settings` | ✅ |
| Notifications | `/app/notifications` | ✅ Real events + read/dismiss |

### Phase 2-5 (localStorage)
| Page | Route | Status |
|------|-------|--------|
| Fuel | `/app/fuel` | ✅ Logs + Idling Cost + CO2 |
| Maintenance | `/app/maintenance` | ✅ Schedule + mark done |
| Scoring | `/app/scoring` | ✅ Driver behavior |
| Telematics | `/app/telematics` | ✅ |
| Analytics | `/app/analytics` | ✅ |
| Dispatch | `/app/dispatch` | ✅ |
| POI | `/app/poi` | ✅ |
| Inspection | `/app/inspection` | ✅ |
| Compliance | `/app/compliance` | ✅ |
| Predictive | `/app/predictive` | ✅ |
| Audit Log | `/app/audit` | ✅ |

### Auth/Special
| Page | Status |
|------|--------|
| ForgotPasswordPage | ✅ |
| RegisterPage | ✅ |
| MobileBlockPage | ✅ (blocks all mobile/tablet) |

---

## CI/CD

```yaml
# .github/workflows/ci.yml
# Trigger: push to main
# Steps: npm ci → npm run build → cloudflare/wrangler-action@v3
# Secrets: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID
```

Manual deploy: `npx wrangler pages deploy dist --project-name=bellerox-gps`

---

## Architecture Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| UI style | Google-inspired, color-fill | Clean, no visual noise, Thai-readable |
| Font | Inter + Sarabun only | Calistoga removed, single unified stack |
| Dropdowns | SearchSelect component | Searchable, keyboard nav, color-fill |
| GPS server | Traccar 6 (open-source) | 200+ protocols |
| Map | Leaflet + OpenStreetMap + Longdo | Free + Thai address quality |
| API proxy | Cloudflare Worker | CORS + hide Traccar server IP |
| Auth | Traccar Basic Auth + cookie | No extra backend |
| Alerts | LINE Notify | Thai businesses use LINE |

---

## Known Issues
1. `traccar.xml`: `${POSTGRES_PASSWORD}` must be in `.env` before Docker start
2. GPS ports must be open in GCP firewall
3. Traccar TCP: stateful, needs sticky sessions for load balancing
4. Leaflet + React 18 Strict Mode: double-init warnings in dev (harmless)
5. Mobile map: Google Maps API key required for react-native-maps on Android
6. CF OAuth token: no DNS:Edit scope — use separate API token for dns-setup.sh
7. WebSocket auth: wss:// uses same JSESSIONID cookie, ensure `withCredentials: true`

---

## Next Priority Tasks

**User must do:**
1. Create GCP VM (e2-standard-4, asia-southeast1-a) → `setup-server.sh` → get IP → `dns-setup.sh`
2. Create CF API token (Zone:DNS:Edit) → `CF_API_TOKEN=<token> bash infrastructure/scripts/dns-setup.sh`
3. Add Pages custom domain: `gps.bellerox.com` in Cloudflare Pages dashboard

**Code tasks:**
1. **[HIGH] Settings System v2.0.0** — Implement 23 sub-menus across 7 categories (4-6 weeks)
   - See: `SETTINGS_README.md` (master doc)
   - Phase 1: User Profile + Core Settings (2 weeks)
   - Phase 2: Asset Management (2 weeks)
   - Phase 3: Driver/Trailer/RFID (1-2 weeks)
2. Multi-language (APAC phase) — i18next setup (EN/TH/VI/ID)
3. Geofence enter/exit alert rules — trigger LINE Notify from events
4. DLT: ลงทะเบียน Vender ID + username/password จาก DLT กรมขนส่ง → ตั้งค่าที่ `/admin/dlt` → เปิด Auto-send

| 2026-08-06 | — | **DLT Fix + UI Timestamps**: (1) Fixed Bangkok-timezone server issue in dltService.ts — added `adjustForBangkokServer()` that detects timestamps 6-8h in future (Bangkok local mislabeled as UTC) and subtracts 7h before DLT send; (2) Changed all UI timestamps from relative ("1 นาทีที่แล้ว") → absolute datetime ("06/08/2569 16:45:13") in LiveMapPage popup + sidebar + FleetPage; tooltip still shows relative time on hover; (3) Added `getDltTimeDiagnostic()` helper + "Time Diagnostic" tab in DLTPage showing fixTime / serverTime / utcTs / corrected / fresh per device; (4) Build ✓ lint clean |
| 2026-07-03 | — | **Settings System Design Complete**: 6 design documents created (SETTINGS_DESIGN.md, SETTINGS_DESIGN_PART2.md, SETTINGS_DESIGN_PART3.md, SETTINGS_IMPLEMENTATION_PLAN.md, SETTINGS_UX_UI_GUIDELINES.md, SETTINGS_SYSTEM_SUMMARY.md, SETTINGS_DEVELOPER_CHECKLIST.md, SETTINGS_README.md) — 7 main categories, 23 sub-menus, 8 new database tables, 40+ API endpoints, 20+ UI components, full UX/UI guidelines, ~2,600 lines of documentation. Features: User Profile (view/edit/change password), Email Report Config (scheduled reports), Alert Notification Config (LINE/Email/SMS), Vehicle CRUD (multi-tab form), Vehicle Groups (tree view), Speed Groups, Maintenance Records, Trailer Management, Driver Management (license expiry alerts), RFID Card Management, System User Management (admin only with RBAC). Ready for implementation. |
| 2026-07-02 | — | **v2.0.0**: 107 features — DashboardPage v2 (health score, quick actions, idle warning, events panel), FleetPage v2 (StatusFilter tabs, grid/table toggle, CSV export, bulk select, CopyButton IMEI), ReportsPage v2 (DatePresets, 4 report types, PDF/CSV, auto-refresh, print), AlertsPage v2 (severity filter, bulk dismiss, sound toggle, CSV export), DriversPage v2 (license expiry warning, performance ranking, status, CopyButton), MaintenancePage v2 (status filter, calendar view, CSV export, search), AlertRulesPage (new — configure thresholds via sliders), ChangelogPage (new — What's New), KeyboardShortcutsModal (new — ? key), CopyButton/ExportMenu/StatusFilter/DatePresets (shared components), Layout: keyboard shortcuts + Changelog nav |

## Completed Work Log
| Date | Commit | What |
|------|--------|------|
| 2026-06-30 | — | Sessions 1-13: Full infrastructure, 30+ pages, design system |
| 2026-06-30 | 3347026 | Auth upgrade (lockout, forgot pw, register, mobile block) |
| 2026-06-30 | — | Mock→Real API (Drivers, Fuel, Maintenance, Notifications) |
| 2026-06-30 | — | Sidebar UX: accordion groups + hover flyout |
| 2026-06-30 | — | CI/CD: rsync→wrangler-action@v3 |
| 2026-06-30 | — | Logo: GPS Global Tracker (black PNG + CSS invert) |
| 2026-06-30 | d48e392 | WebSocket circuit breaker + .env.local URL fix + 400 fix |
| 2026-06-30 | fc028ae | Font unification + Google color palette |
| 2026-06-30 | 80d4703 | Color-fill inputs + SearchSelect component |
| 2026-07-01 | d57c8f2 | SearchSelect rollout: all vehicle pickers |
| 2026-07-01 | 01a33a8 | Font: IBM Plex Sans Thai (replaced Inter + Sarabun) |
| 2026-07-01 | 37a7eef | LINE Notify per-group tokens + dark mode + marker clustering |
| 2026-07-01 | f419e58 | Fix registration, logo size, api.gps.bellerox.com DNS |
| 2026-07-01 | 7d4008f | RegisterPage: pre-check server.registration flag |
| 2026-07-01 | 4eb6453 | Worker: resolveOverride for VM IP bypass (infra) |
| 2026-07-01 | 5ec2830 | CI fix attempt: remove environment:production |
| 2026-07-01 | — | Wrangler manual deploy: https://1b0f3591.bellerox-gps.pages.dev |
| 2026-07-02 | — | DESIGN.md v2: "Signal" brand identity, Section accent colors, component specs |
| 2026-07-02 | — | traccar.types.ts: Added TraccarCommand + TraccarCommandType |
| 2026-07-02 | — | traccarService.ts: Added updateServer, deleteUser, sendCommand, getCommandTypes |
| 2026-07-02 | — | SettingsPage: ServerSettingsSection (admin) — full GET/PUT /api/server UI |
| 2026-07-02 | — | TeamPage: Fixed deleteMutation → uses traccarService.deleteUser |
| 2026-07-02 | — | VehicleDetailPage: Added "ส่งคำสั่ง" tab with DeviceCommandsTab component |
| 2026-07-02 | — | DLT integration: dltService.ts (full spec), DLTPage rewrite, SettingsPage fix, FleetPage + license plate, DLT in nav |
