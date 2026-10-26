# Plan — Mobile: one status rule, place names, no domain screen, per-tenant .aab

Status: done
Created: 2026-10-23 by /toh-plan
Repos: bellerox-gps-mobile (Expo 54) · bellerox-gps-web (/admin) · supabase/functions

## Goal
Make the mobile app tell the truth about vehicles and where they are, and turn /admin into the
place a new customer's Play Store file comes from. Four things:

1. **One status rule.** Mobile computes status with its own `getVehicleStatus(deviceStatus, speed,
   ignition)` — no fix-age check, no never-reported state, ignition read only from
   `attributes.ignition`. Web went through two rounds of fixes and settled on
   `computeVehicleStatus()` (`bellerox-gps-web/src/lib/vehicleStatus.ts`) as the single source of
   truth. Port it to mobile so both apps colour every car identically.
   Measured today: Meitrack/meiligao cars (SMC 86-0373/0606/0607/0608) never set
   `attributes.ignition` — they send `attributes.input` — so they can never be amber, only grey;
   and 2 cars reporting <7 min ago were painted red because Traccar's own `device.status` lagged.
2. **Place names.** Traccar's `position.address` is null for all 54 cached rows, so the sheet shows
   raw lat/lng and the list shows nothing. Use the existing KV-cached Worker
   `GET {api}/geocode?lat=&lon=` (verified live → `ต.บางปลาสร้อย อ.เมืองชลบุรี จ.ชลบุรี`).
   Place appears in: map bottom list · label under the selected marker · selected car bar ·
   vehicle detail + fleet tab. Row layout: name on line 1, place on line 2.
3. **Remove the domain screen** (`app/(domain)/`) and the "เปลี่ยน domain บริษัท" link — the app is
   locked to the domain baked in at build time; new customers get their own build.
4. **/admin → Build → download .aab** for Play Console. The current button is already broken:
   `supabase/functions/trigger-eas-build` POSTs `https://api.expo.dev/v2/builds`, which returns
   **404** (verified). The live API is GraphQL `POST https://api.expo.dev/graphql` —
   `build(buildId) → BuildMutation.createAndroidBuild(appId, job, metadata)` with
   `job.builderEnvironment.env` for per-tenant vars, and `Build.artifacts.applicationArchiveUrl`
   for the file (verified via schema introspection).

**Accepted consequence (agreed at the gate):** porting web's rules verbatim means a car that is
silent >5 min but still has `device.status='online'` shows grey/amber, not red — web behaves this
way today. Changing that is a separate decision, not part of this port.

**Palette decision (2026-10-23, mid-build):** mobile and web had `stopped`/`offline` **swapped**.
Web is authoritative — a `cc155eb` commit (2026-07-02, "ดับเครื่อง=แดง, ออฟไลน์=เทา") deliberately
made `stopped` RED and `offline` GREY across ~6 web files, while CLAUDE.md still carries the
pre-swap values. Mobile follows web: `stopped` `#EA4335` (red) · `offline` `#5F6368` (grey) ·
`unlinked` `#BDC1C6`. CLAUDE.md + `.claude/rules/ui-design.md` get updated to match shipped
reality. This IS the reported symptom: SMC's parked cars are `stopped`, so on web they are red —
mobile painted them grey.

## Stack
- Mobile: Expo 54 · expo-router 6 · React Query · zustand · react-native-webview (Leaflet+Longdo)
- Web /admin: React 18 + Vite + Tailwind, Supabase `cl_tenants`, Deno edge functions
- Data: Traccar REST/WS via `api.centerlink.co.th` · geocode Worker (Workers KV) · no new services

## Pages
| Page | Route | Purpose |
|------|-------|---------|
| Live map | `app/(tabs)/index.tsx` | list rows + marker label show place; correct colours |
| Fleet | `app/(tabs)/fleet.tsx` | row shows place; correct colours |
| Vehicle detail | `app/vehicle/[id].tsx` | place row; correct colours |
| Login | `app/(auth)/login.tsx` | drop "change domain" affordance |
| ~~Domain picker~~ | `app/(domain)/` | DELETED |
| Tenant detail | `/admin/tenants/:id` (web) | per-tenant EAS project + Build + download .aab |

## Done When
- [ ] `npx tsc --noEmit` 0 errors · `npx jest` green · `npm run lint` 0 warnings (mobile)
- [ ] `npm run build` + lint green (web)
- [ ] `grep -rn "(domain)" app src` in mobile → 0 hits; app boots straight to login with tenant brand
- [ ] A live parity script over the production API prints **0** status differences between the
      mobile rule and web's `computeVehicleStatus`
- [ ] One Chonburi car shows ต./อ./จ. in all four surfaces, and no surface shows raw lat/lng as the
      primary place label
- [ ] `/admin` tenant page: pressing Build returns a real EAS build id, status reaches `finished`,
      and Download saves a `.aab` file
- [ ] The four fixed status colours (#22c55e/#f59e0b/#94a3b8/#ef4444) are unchanged

## Phase 0 — One status rule
- [x] T000 design-reviewer — add the `unlinked` 5th token + place-line spec (name line 1 / place
      line 2, ink3, truncate) to `bellerox-gps-mobile/DESIGN.md` §Color System + §List Item
- [x] T001 dev-builder — port web's rule set into `bellerox-gps-mobile/src/lib/vehicleStatus.ts`:
      `computeVehicleStatus()`, `effectiveTime()` (GT06 +7h), `isIgnitionOn()` (incl. Meitrack
      `input` bitmask), `unlinked`, `GPS_STALE_MS`; keep the 4 status colours untouched
- [x] T002 dev-builder — `unlinked` token via `useTheme` in `bellerox-gps-mobile/src/theme/index.ts`
      (both LIGHT_COLORS and DARK_COLORS) + label in `src/components/StatusBadge.tsx`
- [x] T003 [P] dev-builder — tests in `src/lib/__tests__/vehicleStatus.test.ts` + new
      `src/lib/__tests__/statusParity.test.ts` (sweep the shapes web's statusPartition covers)
- [x] T004 dev-builder — rewire map screen to the single source (list rows, markers, status pills,
      keep no-position cars as `unlinked` instead of dropping them)
      in `app/(tabs)/index.tsx`
- [x] T005 dev-builder — rewire `app/(tabs)/fleet.tsx` + `app/vehicle/[id].tsx` +
      `src/components/map/types.ts` + `src/components/map/VehicleDetailSheet.tsx`
- [x] T006 dev-builder — add `scripts/status-parity.mjs` (live API → mobile rule vs web rule)
**Checkpoint:** `npx tsc --noEmit` 0 · `npx jest` green · `node scripts/status-parity.mjs` prints 0 mismatches

## Phase 1 — Place names
- [x] T101 [P] dev-builder — `src/lib/geocode.ts` (Worker `/geocode` client; memory + AsyncStorage
      cache; in-flight dedupe; concurrency 5; 404 = permanent no-coverage, 502 = retry) +
      `src/hooks/useReverseGeocode.ts`, mirroring web's semantics
- [x] T102 ui-builder — map bottom list rows: `name` line + place line
      in `app/(tabs)/index.tsx`
- [x] T103 ui-builder — place in the selected marker's label
      in `src/components/map/LongdoMap.tsx` + `src/components/map/longdoMapHtml.ts` (escape it)
- [x] T104 ui-builder — selected car bar + detail sheet: place instead of raw coordinates
      in `src/components/map/VehicleDetailSheet.tsx`
- [x] T105 ui-builder — place line in `app/(tabs)/fleet.tsx` + `app/vehicle/[id].tsx`
**Checkpoint:** `npx tsc --noEmit` 0 · `npx jest` green · a Chonburi car shows ต./อ./จ. in all four surfaces

## Phase 2 — Remove the domain screen
- [x] T201 dev-builder — delete `app/(domain)/index.tsx` + `app/(domain)/_layout.tsx`; drop the
      change-domain block from `app/(auth)/login.tsx`; remove `setDomain`/`clearDomain` from
      `src/context/TenantContext.tsx` (keep the baked `BUILD_TENANT_DOMAIN` + theme lookup)
**Checkpoint:** `grep -rn "(domain)" app src` → 0 hits · `npx tsc --noEmit` 0 · app boots to login

## Phase 3 — /admin build + .aab download
- [x] T301 dev-builder — rewrite `bellerox-gps-web/supabase/functions/trigger-eas-build/index.ts`
      to GraphQL `createAndroidBuild` (api.expo.dev/graphql) with
      `job.builderEnvironment.env = {TENANT_SLUG, EAS_PROJECT_ID, EAS_SLUG}`
- [x] T302 dev-builder — new `bellerox-gps-web/supabase/functions/eas-build-status/index.ts`:
      query `Build.status` + `artifacts.applicationArchiveUrl`; stream the `.aab` on `?download=1`
      so the EAS token never reaches the browser
- [x] T303 dev-builder — per-tenant build config `cl_tenants.data.build {easProjectId, packageName}`
      + save it from `bellerox-gps-web/src/pages/admin/TenantDetailPage.tsx`
- [x] T304 ui-builder — `MobileAppSection` in `bellerox-gps-web/src/pages/admin/TenantDetailPage.tsx`:
      Build Android → live status → Download .aab
**Checkpoint:** `/admin` tenant page: build returns a real EAS build id; status reaches `finished`;
Download saves a `.aab`  (needs `EXPO_TOKEN` + that tenant's `easProjectId` — else `[!] BLOCKED`)

## Phase 4 — Verify + record
- [x] T401 test-runner — live parity re-run + screenshot the four surfaces from a real session
- [x] T402 test-runner — full Done When sweep (tsc · jest · eslint · web build)
- [x] T403 plan-orchestrator — memory update, commit + push mobile and web, bump parent submodule
      pointers, confirm web CI green

## Dependencies / risks
- `EAS_API_TOKEN` (as `EXPO_TOKEN`) + a per-tenant `easProjectId` must exist before Phase 3 can be
  verified end-to-end. Without them T301–T304 get marked `[!] BLOCKED` — everything else proceeds.
- A real build needs that tenant to exist as an EAS project (`app.config.js` already accepts
  `EAS_PROJECT_ID`/`EAS_SLUG` overrides); the package name is permanent once uploaded to Play.
- Phase 0 changes colours for some cars *by design* — that is the fix, not a regression.

## Out of scope
- Driver Mode / background location, push notifications, iOS builds and store submission
- Cleaning up the legacy `config/tenantConfig.ts` / `services/api.ts` / `services/websocket.ts` chain
- Any change to the four fixed status colours, or to the geocoding Worker itself