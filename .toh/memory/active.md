# 🎯 Active Work

**Status:** ✅ Clean Architecture & OOP Remediation — COMPLETED (2026-11-07)
**Plan:** `.toh/plan.md` (Status: done)

## What shipped (28 tasks · 6 phases)

### Phase 1 — Truth & guardrails
- `npm test` went from **exit 1 → exit 0** (vitest was collecting
  `api-gateway/test/thaiAdmin.test.ts`, which has no suite). Now `include: ['src/**/*.test.{ts,tsx}']`.
- CI (`.github/workflows/build.yml`) runs `npm test`, `lint:ui`, **and** the
  api-gateway type-check + route tests before the build.
- `scripts/check-ui-conventions.mjs` gained 4 rules: `no-raw-fetch`,
  `no-window-confirm`, `no-page-persistence`, `status-palette-lock`.
- `src/components/AppErrorBoundary.tsx` mounted at the root — the SPA can no
  longer blank-screen on a render error.
- `src/lib/logger.ts` — one logging seam; **98 `console.*` calls** in
  services/hooks/lib migrated. `debug`/`info` are dev-only (PDPA: no raw coords).

### Phase 2 — Delete before building
- Removed **2,073 LOC of dead code**: `layout/Layout.tsx` (778, 0 importers),
  `ReportsPageV2/V3`, `ui/{select,form,radio-group,phone-mockups-1}`,
  `services/tenantAssignmentService.ts` (234, 0 importers, called endpoints that
  never existed), `src/.toh/plan.md`.
- **Kept** `components/reports/ReportsTable.tsx` — the plan claimed it was dead;
  it has 3 live consumers. Verification before deletion is now a standing rule.
- `/reports-v1` renamed `/reports-full` — it is the 7-tab superset, not an older copy.

### Phase 3 — One data path
- `services/httpClient.ts` — typed fetch seam for our own backend (ApiError,
  401→logout, abortable).
- `hooks/useAdmin.ts` — admin audit + RBAC off raw `fetch`.
- `services/mapSearchService.ts` — Nominatim + OSRM out of
  `LiveMapPage`/`RoutePlanner`, now cached and abortable.
- `ScoringPage` — **`MOCK_DRIVERS` removed**; real events + summary-report
  distance; honest empty state; `ℹ` glyph replaced with a Lucide icon.
- `services/recordRepository.ts` + `hooks/useRecords.ts` +
  `supabase/migrations/20261106000000_operational_records.sql` — **7 tables**;
  Fuel / Maintenance / Inspection / Dispatch / Predictive / AlertRules no longer
  use localStorage as a database.

### Phase 4 — Backend completion
- `api-gateway` split into `app.ts` (routes) + `server.ts` (process).
- `middleware/auth.ts` — Traccar session verification → `superadmin` /
  `tenant_admin` / `user`; `middleware/validate.ts` — typed param parsing.
- `routes/admin.ts` — `/api/admin/audit`, `/audit/stats`, `/roles`,
  `/users/:id/roles` (these were **guaranteed 404s** before).
- `routes/tenants.ts` — `/api/tenants/overview`, `/:id/users`, `/:id/devices`.
- `infrastructure/postgres/init-admin.sql` — audit + RBAC tables, seeded roles
  and permissions; `scripts/apply-admin-schema.sh` applies it (initdb only runs once).
- nginx routes `^/api/(admin|tenants)` to the gateway before the Traccar catch-all.
- `api-gateway/test/run.ts` — 10 route-contract tests (401 on every protected
  route, 404 shape, Thai geocoder).

### Phase 5 — Domain model & decomposition
- `src/domain/Vehicle.ts` — the fleet entity; delegates to `computeVehicleStatus`
  (no rule duplication), exposes `toSnapshot()` / `counts()` / `byAttention()`.
  7 unit tests.
- `src/services/BaseService.ts` — `query`/`mutate`/`unwrap` + `ServiceError`
  with a Thai `userMessage`. 6 unit tests.
- `DLTPage.tsx` **1,880 → 1,004 LOC**; 6 components extracted to
  `components/dlt/` (`BatchStatus`, `DltKpi`, `ConnectionHealth`,
  `MasterfileRegisterModal`, `TimeDiagPanel`, `GpsModelsTab`).
- 5 hand-rolled `toLocaleString('th-TH')` date sites → `lib/timezone.ts`
  (Bangkok-explicit; the old form followed the *machine* timezone).

### Phase 6 — Security & parity
- **T025** — DLT credentials no longer written to `localStorage`
  (`services/dltService.ts`). Non-secret fields persist; username/password live
  in memory + Traccar user attributes. Legacy rows are scrubbed on read.
  4 tests assert the password never reaches disk.
- **T026** — RLS audit found `dlt_manual_overrides` and `dlt_transmission_logs`
  with **no RLS at all** (GPS coordinates + operator identity, readable with the
  publishable key). `supabase/migrations/20261107000000_rls_hardening.sql` fixes
  those plus `cl_slot_cleanup_log`; `supabase/migrations/README.md` documents the
  anon/authenticated/service_role model.
- **T027** — web↔mobile drift fixed: mobile `STATUS_COLOR` still used the old
  Tailwind palette, `vehicleSprites.ts` on web too, and mobile `formatSpeed` /
  `formatDistance` lacked `Math.abs` (negative speeds). Both apps now pin the
  same contract via matching `unitsParity.test.ts` tables.

## Verification (all run at close-out)
| Gate | Result |
|---|---|
| `npx tsc --noEmit` (web) | 0 errors |
| `npx tsc --noEmit` (api-gateway) | 0 errors |
| `npx tsc --noEmit` (mobile) | 0 errors |
| `npm run build` (web) | exit 0 |
| `npm test` (web) | **162 passed** (15 files) |
| `npm test` (api-gateway) | **10 passed** |
| `npx jest` (mobile) | **57 passed** |
| `npm run lint` | 0 errors, 42 pre-existing warnings |
| `npm run lint:ui` | 241 files, 0 violations |

## Page decomposition progress (T023)
Three more pages split after the first push (commit `0d8bd26`):

| Page | Before | After | Extracted to |
|---|---|---|---|
| `ReportsPage` | 1,411 | **415** | `components/reports/tabs/*` (7 tabs) + `ReportTable.tsx` |
| `SettingsPage` | 1,147 | **332** | `components/settings/sections/*` + `settingsShared.tsx` |
| `TeamPage` | 1,014 | **676** | `components/team/{CreateUserModal,AssignGroupsPanel}` + `teamShared.ts` |

The linter earned its keep here: the LINE token storage and the Notify POST
moved into a component with the JSX, and `no-raw-fetch` / `no-page-persistence`
failed the build. Both now go through `services/lineNotifyService.ts`.

## Carried forward
- **T023 remaining** — 18 pages still >500 LOC. The four largest need a full read
  before splitting, not a mechanical move: `FleetPage` 1107, `LiveMapPage` 1040,
  `DLTPage` 1002, `TripReplayPage` 897. Then `NotificationsPage` 894,
  `VehicleDetailPage` 777, `DriversPage` 695, `TrailersPage` 661,
  `admin/TenantDetailPage` 658, `AccountSettingsPage` 652, `DashboardPage` 634,
  `FuelPage` 623, `ScoringPage` 581, `BillingPage` 558,
  `EmailReportSettingsPage` 532, `AlertsPage` 517, `MaintenancePage` 503.
- 42 ESLint `any` warnings, 37 of them in `lib/reportGenerators.ts`.
- CI submodule checkout still needs `PAT_TOKEN` ([[ci-pat-token-blocker]]).