# 🧩 Component Registry

> Check this file **and** `bellerox-gps-web/src/components/ui/index.ts` before building anything.
> DESIGN.md §10 Reuse Law: extend an existing API; never fork a component.

## UI primitives — `src/components/ui/` (the closed set)

| Component | File | Purpose |
|---|---|---|
| `DataTable<T>` | `data-table.tsx` | Every record list. Columns = `ColumnDef<T>[]`, state = `ListController<T>`. Sticky header, row select, sort, overflow menu, mobile cards, states, pagination |
| `DataTableToolbar` | `data-table-toolbar.tsx` | Search + filters + actions + active-filter chips + bulk counter |
| `DropdownMenu` | `dropdown-menu.tsx` | Row overflow (⋯) and toolbar menus; keyboard nav |
| `ConfirmDialog` | `confirm-dialog.tsx` | Destructive confirmation. Replaces `window.confirm` |
| `DateTimeRangePicker` | `DateTimeRangePicker.tsx` | Bangkok-time range selection for reports |
| `Pagination` | `pagination.tsx` | 15/25/50, range text, prev/next |
| `SearchSelect<V>` | `search-select.tsx` | Searchable dropdown (single implementation) |
| `Checkbox` | `checkbox.tsx` | Native checkbox + indeterminate |
| `Skeleton` / `TableSkeleton` | `skeleton.tsx` | Loading placeholders |
| `Button` `Badge` `Card` `Input` `Label` `Textarea` `Tabs` `Dialog` `Table` | `*.tsx` | Base primitives |
| barrel | `index.ts` | Import from `@/components/ui` |

## Domain model — `src/domain/`

| Entity | File | Responsibility |
|---|---|---|
| `Vehicle` | `Vehicle.ts` | Fleet entity. `fromTraccar()`, `status()`, `toSnapshot()`, `counts()`, `byAttention()`. Delegates status rules to `lib/vehicleStatus.ts` — never re-implements them |

## Table object model — `src/lib/table/`

| Class | File | Responsibility |
|---|---|---|
| `ColumnDef<T>` / `col<T>()` | `ColumnDef.ts` | Column identity, accessor, search text, sort value, renderer |
| `QueryState` | `QueryState.ts` | Immutable search / filters / sort / page state |
| `RowSelection` | `RowSelection.ts` | Select, deselect, selectAll, indeterminate — scoped to visible rows |
| `ListController<T>` | `ListController.ts` | Owns rows + query + selection; snapshot for React |

## Service layer — `src/services/`

| Service | File | Responsibility |
|---|---|---|
| `BaseService` | `BaseService.ts` | Contract for all services: `query`/`mutate`/`unwrap`, `ServiceError` with Thai `userMessage`, `userMessageOf()` |
| `httpClient` | `httpClient.ts` | Typed fetch seam for **our** backend (api-gateway). `ApiError`, 401→logout, abortable |
| `traccarService` | `traccarService.ts` | All Traccar REST calls |
| `recordRepository` | `recordRepository.ts` | `RecordRepository<T>` CRUD over Supabase (+ documented local fallback). One repo export per record kind |
| `mapSearchService` | `mapSearchService.ts` | Nominatim place search + OSRM routing, cached and abortable |
| `dltService` | `dltService.ts` | DLT portal integration. **Credentials are memory + Traccar attributes only — never localStorage** |
| `geocodingService` | `geocodingService.ts` | Longdo address lookup with in-memory cache |

## Hooks

| Hook | File | Purpose |
|---|---|---|
| `useListController` | `hooks/useListController.ts` | `useSyncExternalStore` adapter for `ListController` |
| `useRecords` | `hooks/useRecords.ts` | React Query adapter for `RecordRepository` (list + create/update/remove) |
| `useAdmin` | `hooks/useAdmin.ts` | `/api/admin/*` — audit log, stats, RBAC roles, role assignment |
| `useDevices` / `useVehiclesWithPositions` | `hooks/useDevices.ts` | Traccar devices + computed status |
| `useTraccarWebSocket` | `hooks/useTraccarWebSocket.ts` | Real-time position merge |
| `useGeofences` `useReports` `useDrivers` `useTrailers` `useGroups` | `hooks/` | React Query data access |

## Shared infrastructure

| Module | File | Purpose |
|---|---|---|
| `logger` | `lib/logger.ts` | Single logging seam. `createLogger(scope)`; debug/info dev-only; never log coordinates |
| `AppErrorBoundary` | `components/AppErrorBoundary.tsx` | Root render-error guard with retry + error id |
| `timezone` | `lib/timezone.ts` | **All** Thai date/time formatting. Never hand-roll `toLocaleString('th-TH')` |
| `units` | `lib/units.ts` | knots→km/h (whole numbers), distances, durations. Pinned by `unitsParity.test.ts` |
| `vehicleStatus` | `lib/vehicleStatus.ts` | Status rules — the single source of truth (called by `domain/Vehicle`) |
| `check-ui-conventions` | `scripts/check-ui-conventions.mjs` | CI guard: emoji, raw table, hex-in-ui, duplicate primitives, raw fetch, window.confirm, business localStorage, **status palette lock** |

## Feature components — `src/components/dlt/` (split from DLTPage, 2026-11-07)

`BatchStatus.tsx` (skip breakdown + transmission badges) · `DltKpi.tsx` ·
`ConnectionHealth.tsx` · `MasterfileRegisterModal.tsx` · `TimeDiagPanel.tsx` ·
`GpsModelsTab.tsx` (self-contained CRUD) · `ActiveOverridesTable.tsx` ·
`OverrideForm.tsx` · `TransmissionHistoryTable.tsx`

## Pages already on the DataTable standard

`FleetPage` · `DriversPage` · `TrailersPage` · `AdminUsersPage` · `AuditLogPage` · `TableLabPage`

Still rendering a raw `<table>` (allowlisted in `scripts/check-ui-conventions.mjs`,
each entry a migration task): `DLTPage` · `SpeedPage` · `FuelPage` · `MaintenancePage` ·
`BillingPage` · `ApiDocsPage` · `ReportsPage` · `admin/BillingAdminPage` ·
`admin/AdminVehiclesPage` · `admin/AdminServerConfigPage` · `admin/AdminDLTPage` ·
`components/reports/ReportsTable`

## Backend — `bellerox-gps-web/api-gateway/`

| Module | File | Purpose |
|---|---|---|
| app | `app.ts` | Express app factory (routes + middleware, no listen) — importable by tests |
| server | `server.ts` | Env loading, listen, SIGTERM/SIGINT |
| auth | `middleware/auth.ts` | Traccar session verify → `superadmin`/`tenant_admin`/`user`; `requireRole` |
| validate | `middleware/validate.ts` | Typed query/body parsing; `ValidationError` → 400 |
| admin routes | `routes/admin.ts` | `/api/admin/audit`, `/audit/stats`, `/roles`, `/users/:id/roles` (superadmin only) |
| tenant routes | `routes/tenants.ts` | `/api/tenants/overview`, `/:id/users`, `/:id/devices` (role-scoped) |
| tests | `test/run.ts` | 10 route-contract tests — `npm test --prefix api-gateway` |

## Stores (Zustand)

| Store | File | State |
|---|---|---|
| `authStore` | `stores/authStore.ts` | Credentials, session, tenant |
| `themeStore` | `stores/themeStore.ts` | Light / dark / system |
| `mapSettingsStore` | `stores/mapSettingsStore.ts` | Map layer, follow-selected |
| `billingStore` `dltSendStore` `adminStore` | `stores/` | Feature-scoped UI state |

Never put GPS positions in a store — React Query owns them.

---
*Updated: 2026-11-07 — clean architecture & OOP remediation*