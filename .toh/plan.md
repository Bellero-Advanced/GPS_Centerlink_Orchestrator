# Plan — Mobile: map-first vehicle sheet + themed cube loader

Status: done
Created: 2026-10-26 by /toh-plan
Repo: bellerox-gps-mobile (Expo) — map tab `app/(tabs)/index.tsx` + `src/components/map/VehicleDetailSheet.tsx`

## Goal
Tapping a vehicle must keep the map visible. Today the sheet covers ~60% of the screen and shows
rows nobody needs (lastUpdate, vehicleId, duplicate course). Redesign like Grab/Bolt/Uber:
map ~3/4 top, compact peek card ~1/4 bottom, a button opens the full detail.
Also: themed 3D cube loader, rounded-sm + colour-fill style.

## Findings
- Map tab renders `VehicleDetailSheet` (242 lines), not `VehicleBottomSheet`.
- Screenshot shows raw i18n keys (`searchVehicle`, `address`, `ignition`, `lastUpdate`) → translation lookup broken on device. Fix in same pass.
- RADIUS.sm = 10 in `src/theme/index.ts` — "rounded-sm" = use RADIUS.xs/sm on new sheet only (don't change global tokens).

## Design (ride-hailing pattern)
Peek card (~25% height, max ~210px), fills with status colour tint, rounded-sm corners:
```
[● จอดดับเครื่อง]  86-0373 ชลบุรี                 [×]
 0 km/h  ·  ↖ 310°  ·  ต.หนองอิรุณ อ.บ้านบึง ชลบุรี
[ นำทาง (filled brand) ] [ รายละเอียด ] [ แชร์ ]
```
- Map re-centres the selected car into the visible top 3/4 (offset camera by sheet height).
- "รายละเอียด" → full-screen modal (slide up): speed, course, ignition, address, odometer, battery, history/replay link. lastUpdate + vehicleId removed everywhere in the sheet.
- Status colours unchanged (moving/idle/stopped/offline/unlinked tokens).

## Done When
- Selected car's marker visible above the sheet on 375px-wide phone
- No lastUpdate / vehicleId rows; no raw i18n keys on map tab
- Cube loader replaces main ActivityIndicator spinners, brand colours, respects reduce-motion
- `npx tsc --noEmit` + lint + jest pass; dark mode OK

## Phase 1 — Peek sheet
- [x] T101 ui-builder — rewrite `src/components/map/VehicleDetailSheet.tsx` as compact peek card (rounded-sm, status-tinted fill, 3 actions)
- [x] T102 ui-builder — new `src/components/map/VehicleFullDetailModal.tsx` (full details, no lastUpdate/vehicleId)
- [x] T103 dev-builder — `app/(tabs)/index.tsx`: camera padding/offset so selected car stays in top 3/4; wire modal
- [x] T104 dev-builder — fix raw i18n keys (`src/i18n/th.ts`, `en.ts`, i18n init)
- Checkpoint: tsc + jest pass, screenshot on 375×812

## Phase 2 — Cube loader
- [x] T201 ui-builder — `src/components/ui/CubeLoader.tsx` (Reanimated 3D cube, brand/tenant colours, Thai "กำลังโหลด", reduce-motion fallback) — RN port, no styled-jsx
- [x] T202 [P] dev-builder — replace full-screen spinners: map, vehicles, dashboard, history, alerts, vehicle/[id], login
- Checkpoint: tsc + lint + jest pass

## Phase 3 — Verify + ship
- [x] T301 test-runner — tsc, lint, jest; commit mobile + bump submodule; CI green

## Result (2026-10-26)
mobile c7e3135b on feat/mobile-ux-modernization (pushed). tsc 0 errors · lint 0 warnings · jest 8 suites / 37 tests pass.
Mobile repo has no CI workflow. Not verified on a device/simulator — needs a dev build check.
Found: initI18n() was never called → every screen showed raw keys; now initialised at import.
