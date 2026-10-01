# Plan — Mobile App UX/UI Modernization (align with web + TenantTheme)

Status: approved
Repo: bellerox-gps-mobile (Expo 54 / RN 0.81 / expo-router 6) · + bellerox-gps-web (phone mockup only)

## Goal
Modern, bug-free mobile app with the same look and data rules as web; all colors from `src/theme/tenantTheme.ts`.
Core: Live Map · History/Replay · Settings. Plus: Alerts · Vehicle Detail · DLT Manual · quick wins.

## Backend rule (same as web)
- One backend: Go api-gateway + Traccar at `api.centerlink.co.th` (allowlist `api.centerlink.co.th`, `api.gps.bellerox.com`, same as web `traccarApiBase.ts`)
- Same users: Traccar Basic auth, same accounts as web login
- Same tenants: Supabase `cl_tenants` (match by `domain`, then `slug`); brand from `data.theme`, API from `data.gps.traccarUrl`
- Same endpoints as web `traccarService.ts`: `/api/fleet/trips|stops`, `/api/reports/events`, `/api/socket`
- Remove legacy `services/api.ts` (`/auth/login` JWT), `services/websocket.ts`, `config/tenants.json` runtime use

## Done When
- `npx tsc --noEmit` = 0 errors (currently fails: notifications.ts NotificationBehavior, sync.ts/websocket.ts Timeout)
- `npm run lint` = 0 warnings · `npm test` green
- No hardcoded hex in screens (except fixed vehicle status colors); every screen uses useTheme()
- Dark mode + 375px OK; Thai text Sarabun; loading/empty/error states on every screen
- Vehicle status only via computeVehicleStatus() (same rule as web)

## Phases

### Phase 0 — Foundation
- [x] T000 design-reviewer — mobile section in root DESIGN.md (tokens from tenantTheme, radius, motion 150–250ms)
- [x] T001 dev-builder — fix 3 tsc errors (`src/services/notifications.ts`, `sync.ts`, `websocket.ts`)
- [x] T002 dev-builder — 5 tabs: แผนที่ · ย้อนหลัง · แจ้งเตือน · รถ · ตั้งค่า; merge/remove duplicate screens (map, vehicles, replay, trips, dashboard, profile)
- [x] T003 [P] ui-builder — themed primitives in `src/components/ui/` (Card, Chip, Sheet, ListRow, Segmented, IconButton)
- Checkpoint: tsc 0 errors, app boots

### Phase 1 — Live Map (`app/(tabs)/index.tsx`)
- [ ] T101 ui-builder — full-screen map, floating search, status chips with counts, bottom-sheet vehicle list
- [x] T102 dev-builder — WebSocket + 10s fallback, clustering >100, fit-all / follow controls
- [x] T103 ui-builder — marker tap → peek sheet (speed, address, updated ago; นำทาง / ย้อนหลัง / รายละเอียด)
- Checkpoint

### Phase 2 — History / Replay (`app/(tabs)/history.tsx`)
- [x] T201 ui-builder — vehicle + date picker (วันนี้/เมื่อวาน/7 วัน), trips & stops timeline from `/api/fleet/trips|stops`
- [x] T202 dev-builder — replay: polyline, play/pause, 1×/4×/16×, scrubber, speed-colored route
- Checkpoint

### Phase 3 — Vehicle Detail · Alerts · Settings
- [x] T301 ui-builder — `app/vehicle/[id].tsx`: ภาพรวม / วันนี้ (km, trips, idle) / อุปกรณ์ (IMEI, battery, GSM)
- [x] T302 ui-builder+dev — Alerts grouped by day, severity filter, push (expo-notifications), tap → vehicle
- [x] T303 ui-builder — Settings: theme light/dark/system, TH/EN, map type, notification toggles, account, logout, version
- Checkpoint

### Phase 4 — DLT Manual
- [x] T401 dev-builder — mobile screen on Supabase `dlt_manual_overrides` (anon RLS, created_by from authStore): start/stop, active list, history — same shape as web DLTManualPage
- Checkpoint

### Phase 5 — Quick wins
- [x] T501 Share vehicle location (expo-sharing)
- [x] T502 Navigate to vehicle (open Google/Apple Maps)
- [x] T503 Pinned/favorite vehicles on top
- [x] T504 Pull-to-refresh + offline banner + last-known cache
- [x] T505 Haptics + skeletons everywhere
- Checkpoint

### Phase 6 — Web: app showcase (phone mockup)
- [x] T601 ui-builder — add `phone-mockups-1.tsx` + `phone-mockups-1-utils/phone-carousel.tsx` to web `src/components/ui/` (shadcn already there: button.tsx, card.tsx…); install `@radix-ui/react-slot` `class-variance-authority` pinned if missing; images = real screenshots of new mobile app in `public/mobile/`
- Checkpoint: web build + lint pass

### Phase 7 — Verify
- [ ] T701 test-runner — tsc, lint, jest; unit tests for status + replay interpolation; iOS sim pass on every screen, light + dark
