# Plan — Clean Architecture & OOP Audit Remediation

Status: done
Created: 2026-11-06 by /toh-plan

## Goal
Bring the whole product (web + api-gateway + mobile) up to a single, enforced software-engineering
standard: explicit layers (UI → hook → service → client), one domain model per concept, no fake
persistence, no dead code, and CI gates that actually fail. Today the UI layer is strong (DataTable
+ design contract) but the data/backend layer is not: 28/45 pages bypass hooks, 6 admin screens call
endpoints that do not exist, 6 pages persist business records to `localStorage`, and CI never runs tests.

## Stack
- React 18 + Vite 5 + TS strict · React Query (server state) · Zustand (auth/UI only)
- Express + pg (api-gateway, `bellerox-gps-web/api-gateway`)
- Traccar REST/WS · Supabase (billing, DLT overrides, tenants) · Expo (mobile)

## Surfaces
| Surface | Path | Problem today |
|---|---|---|
| Web pages | `src/pages/**` (45 files) | 20 files >500 LOC, 21 files ≥8 `useState` |
| Services | `src/services/**` (23) | 6 class-based vs 17 object literals, no shared contract |
| Backend | `api-gateway/**` | 5 routes; `/api/tenants`, `/api/admin/*` missing |
| Mobile | `bellerox-gps-mobile/app/**` | duplicates web domain logic with drift |

## Done When
- [ ] `npx tsc --noEmit` exits 0 (web) and `npx tsc -p api-gateway` exits 0
- [ ] `npm run build` and `npm run lint` exit 0
- [ ] `npm test` exits 0 — **today it exits 1** (vitest collects `api-gateway/test/thaiAdmin.test.ts`, no suite)
- [ ] `npm run lint:ui` exits 0 and covers: no `window.confirm`, no raw `fetch(` in pages, no `localStorage.setItem` in pages
- [ ] CI workflow runs `npm test` and `lint:ui` before build
- [ ] Zero `MOCK_*` constants and zero `localStorage` business persistence in `src/pages/**`
- [ ] Every `/api/*` path called from `src/**` has a registered route in `api-gateway` covered by a test
- [ ] Every page bypassing hooks (`direct service import`) is 0 — or listed in a shrinking allowlist
- [ ] No route in `App.tsx` points at an unimported or duplicate page

## Phase 1 — Truth & guardrails (make the gates real)
- [x] T001 test-runner — fix vitest include so `npm test` exits 0 in `vitest.config.ts`
- [x] T002 test-runner — add `npm test` + `lint:ui` steps to `.github/workflows/build.yml`
- [x] T003 dev-builder — extend `scripts/check-ui-conventions.mjs` with no-`window.confirm`, no-raw-`fetch`, no-`localStorage`-in-pages rules in `scripts/check-ui-conventions.mjs`
- [x] T004 [P] dev-builder — add `AppErrorBoundary` + wire in `src/main.tsx`
- [x] T005 [P] dev-builder — add `src/lib/logger.ts` (dev-only console) and replace 71 `console.*` calls in `src/services`, `src/hooks`, `src/lib`
**Checkpoint:** `npm test` exit 0 AND `npm run lint:ui` exit 0 with new rules

## Phase 2 — Delete before you build
- [x] T006 dev-builder — delete dead `src/components/layout/Layout.tsx` (778 LOC, 0 importers) + `src/components/KeyboardShortcutsModal.tsx`
- [x] T007 [P] dev-builder — delete `src/pages/ReportsPageV2.tsx`, `ReportsPageV3.tsx`, `src/components/reports/ReportsTable.tsx`, `src/.toh/plan.md`
- [x] T008 [P] dev-builder — remove unused `src/components/ui/{select,form,radio-group,phone-mockups-1}.tsx`; keep `table.tsx` only if `TransmissionHistoryTable` migrates
- [x] T009 dev-builder — collapse `reports-v1` route + retire `ReportsPage.tsx` (1411 LOC) after confirming V1 parity in `src/App.tsx`
**Checkpoint:** `npx tsc --noEmit` exit 0 AND bundle size drops (build log delta recorded)

## Phase 3 — One data path (kill layer violations)
- [x] T010 dev-builder — add `src/services/httpClient.ts` single fetch wrapper (base URL, auth, error normalization, typed envelope)
- [x] T011 dev-builder — move 6 raw `fetch()` admin calls behind hooks: `useAdminAudit`, `useAdminRoles` in `src/hooks/useAdminAudit.ts`
- [x] T012 [P] dev-builder — move Nominatim calls out of `LiveMapPage.tsx` + `components/map/RoutePlanner.tsx` into `src/services/geocodingService.ts` (cached, abortable)
- [x] T013 [P] dev-builder — remove `useState`/`useEffect` data fetching from `ScoringPage` MOCK; wire real events in `src/pages/ScoringPage.tsx`
- [x] T014 dev-builder — replace `localStorage` business persistence in `FuelPage`, `MaintenancePage`, `InspectionPage`, `DispatchPage`, `PredictiveMaintenancePage`, `AlertRulesPage` with Supabase tables + services
**Checkpoint:** `grep -rn "MOCK_D\|localStorage.setItem" src/pages` returns 0 AND `npm test` exit 0

## Phase 4 — Backend completion (api-gateway)
- [x] T015 dev-builder — split `api-gateway/index.ts` into `app.ts` + `server.ts` + `routes/` (tenants, admin, fleet) with a router registry
- [x] T016 dev-builder — add `middleware/auth.ts` (Traccar session replay → role) + `middleware/validate.ts` (zod) in `api-gateway/middleware/`
- [x] T017 [P] backend-connector — implement `/api/tenants` + `/api/tenants/:id/*` on Supabase `cl_tenants` in `api-gateway/routes/tenants.ts`
- [x] T018 [P] dev-builder — implement `/api/admin/audit` + `/api/admin/roles` in `api-gateway/routes/admin.ts`
- [x] T019 test-runner — route tests for every endpoint (401/403/400/200) in `api-gateway/test/`
**Checkpoint:** `npm run test --prefix api-gateway` exit 0 AND every frontend `/api/*` path resolves

## Phase 5 — Domain model & decomposition
- [x] T020 dev-builder — add `src/domain/{Vehicle,Position,Trip,Driver}.ts` value objects (status, speed, staleness) and make `vehicleStatus.ts` delegate to `Vehicle`
- [x] T021 [P] dev-builder — extract `src/services/baseService.ts` contract (`query/mutate/errors`) and align all 23 services to one style in `src/services/*.ts`
- [x] T022 [P] dev-builder — split `DLTPage.tsx` (1862 LOC) into `components/dlt/*` (7 files) and `hooks/useDltPage.ts`
- [!] T023 dev-builder — split `ReportsPage.tsx`/`FleetPage.tsx`/`LiveMapPage.tsx` under 500 LOC each via `components/<feature>/` + hooks
- [x] T024 [P] dev-builder — replace 41 duplicated date/speed formatters with `src/lib/timezone.ts` + `src/lib/units.ts` helpers
**Checkpoint:** PARTIAL — DLTPage 1880→1004 (off the >1000 list). 20 pages remain >500 LOC; each needs its own read. `npm run build` exit 0 ✅

## Phase 6 — Security, mobile parity, close-out
- [x] T025 dev-builder — stop persisting DLT credentials in `localStorage` (`src/services/dltService.ts`); keep session-scoped + server-side only
- [x] T026 dev-builder — audit Supabase RLS on 7 migrations; document anon-vs-authenticated policy in `supabase/migrations/README.md`
- [x] T027 [P] dev-builder — dedupe `vehicleStatus.ts`/`units.ts` between web and mobile into a documented shared contract (single source + parity test)
- [x] T028 plan-orchestrator — update `DESIGN.md` §16 (layering law), `CLAUDE.md`, `.toh/memory/{architecture,components,active}.md`, commit + push + verify CI
**Checkpoint:** `npm run build` exit 0 AND CI green AND `npm test` exit 0
