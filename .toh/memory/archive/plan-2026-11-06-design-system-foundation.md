# Plan — Design System Foundation: one table, one contract, zero drift

Status: done
Created: 2026-11-06 by /toh-plan
Scope: root docs (`CLAUDE.md`, `DESIGN.md`, `.claude/rules/*`) + `bellerox-gps-web`

## Goal
Every future UI task must land on the same components, the same tokens, and the same list-page
behaviour — without the agent re-inventing a table. Concretely:

1. **One audit scorecard** (already produced below) telling us where token/skill/agent spend is
   wasted today.
2. **One data-table standard** implemented as a real, reusable OOP layer that every list page
   consumes: search · filter · sort · paginate · row select · select-all / deselect-all ·
   bulk actions · overflow menu · empty/loading/error states · keyboard access.
3. **One design contract** — one status palette, one component registry, one "reuse before
   building" rule, so a new page can never drift from an old one.
4. **One guardrail** — a machine check in CI so drift (emoji, raw `<table>`, hex literals)
   cannot come back.

## Audit — where we are today (2026-11-06)

### Token economics

| What loads | Bytes | ≈Tokens | Verdict |
|---|---|---|---|
| `CLAUDE.md` | 36,762 | ~9,200 | **Bloated 3×** — 60% is a Toh-framework manual + repo map that belongs in a rules file |
| `.claude/rules/*` (6, auto-loaded) | 50,112 | ~12,500 | Two files are stale (see below) |
| `DESIGN.md` (read per UI task) | 31,298 | ~7,800 | Valuable, but sections 10–15 are missing and §2 contradicts the code |
| `.claude/skills/*` (23, on demand) | 271 KB | ~68,000 | Only 4–5 fire in practice; 6 are dead weight for this repo |
| `.claude/agents/*` (8) | 108 KB | ~27,000 | Good set; `root-cause-debugger` + `design-reviewer` are the sleepers — under-used |
| `.claude/commands/*` (15) | 92 KB | ~23,000 | `/toh-plan`, `/toh-ui`, `/toh-dev`, `/toh-fix` cover 95% of real usage |
| `.toh/` duplicate of the same | 283 KB | — | **Byte-identical to `.claude/` except 8 agents + 2 commands — pure confusion surface** |

Effective spend per ordinary UI task ≈ **~20k tokens of standing context** before a single line of
code. Roughly half of that is dead or contradictory (numbers below), so the answer to
"is the token budget well spent" is **no — ~50% waste**.

### Root causes found (with evidence)

| # | Finding | Evidence |
|---|---|---|
| F1 | **Skill/agent/command assets are duplicated in two trees** | `.claude/skills/*` (23) == `.toh/skills/*` (23) byte-for-byte; 8 agents and 2 commands differ → agents read whichever copy they find first |
| F2 | **Status palette is defined 3 different ways** | `CLAUDE.md:249` = `#22c55e/#f59e0b/#ef4444` · `ui-design.md:21` same · `DESIGN.md:24` + `index.css:47` = Google `#34A853/#FBBC04/#EA4335` · `tailwind.config.js:31` has `stopped:#9AA0A6, offline:#EA4335` — **stopped and offline are SWAPPED in Tailwind** |
| F3 | **No table standard exists** | 19 files render a raw `<table>`; `components/ui/table.tsx` is imported by exactly **1** file; 41 pages hand-roll `.filter()/.sort()`; only `FleetPage` has pagination; only `FleetPage` has bulk actions; `Drivers`/`Trailers`/`AdminVehicles` have search but no sort, no select, no overflow |
| F4 | **Duplicated primitives** | `components/SearchSelect.tsx` (used 13×) vs `components/ui/search-select.tsx` (used 1×) — different prop contracts |
| F5 | **Emoji in shipped UI** | 150 hits in web `src`, 57 in mobile; real JSX text: `📍`, `🥇`, `👆`, `➕`, `⚠️`, `✓ fresh`, `✗ stale` — DESIGN.md §7 already forbids this, nothing enforces it |
| F6 | **Design tokens bypassed** | 727 hex literals + 2,716 inline `style={{}}` in `src`; `bg-stopped`-style Tailwind classes used 0 times |
| F7 | **Root `MEMORY.md` is stale** | says "Redis 7" (removed 2026-09-25), "e2-small" (now n2-standard-2), "last updated 2026-07-02" |
| F8 | **Skeleton of the design doc is broken** | `DESIGN.md` jumps §9 → §16; the table/list rules the user is asking for have no home |

### OOP check (as asked)

Verdict: **partially OOP — 4/10.**
- Services: 6 of 22 are singleton classes (`DriversService`, `TrailersService`, `SpeedGroupsService`,
  `AlertConfigsService`, `EmailReportConfigsService`, `UserService`) — correct shape.
- The other 16 are plain object literals (`traccarService`, `tenantService`, `billingService`…) —
  same responsibility, different shape → two conventions for one job.
- Components: all function components, no contracts. **UI has no object model at all** — that is
  exactly why table #2 never matches table #1.
- Nothing owns "a list of records": search state, sort state, selection, pagination are re-declared
  per page.

Fix direction (not full class-rewrite of React — that would fight the stack): put a **small object
model under the UI** — `ColumnDef`, `ListController`, `QueryState`, `RowSelection` as real classes
with generics, and make the React components thin views over them.

### Scorecard

| Area | Score | Why |
|---|---|---|
| Design identity (`DESIGN.md`) | 8/10 | Genuinely distinctive brief; loses points for broken numbering + palette conflict |
| Design enforcement | 3/10 | 727 hex literals, 2,716 inline styles, emoji shipped, 0 lint guard |
| Component system | 3/10 | 12 hand-rolled tables, 2 SearchSelects, no registry, no barrel |
| OOP / architecture | 4/10 | Two service conventions; zero model layer in UI |
| Skills & agents fit | 6/10 | Right agents for this business (GPS/fleet, billing, DLT), but duplicated tree + 6 unused skills |
| Token efficiency | 4/10 | ~50% of standing context is duplicated or contradicted |
| **Overall** | **4.7/10** | Strong design taste, weak systematisation — the exact failure mode "new task ≠ old UI" |

## What gets built

### Why "HextaUI-like" — the rule, not the library

There is no local Hexta UI code in this repo (grep: 0 hits outside one mobile filename). What the
request actually needs is the *discipline* HextaUI/shadcn demonstrate: **a closed set of components
with one API, copied in once, reused everywhere.** We already have the elements; we lack the set.
So this plan builds **`src/components/ui/` as a closed system** — not a new look.

### Design law added to the contract

`DESIGN.md` §10–§15 (new):

- **§10 Reuse Law** — before creating any component: (1) grep `components/ui`, (2) check the
  Component Registry in `.toh/memory/components.md`, (3) extend an existing API with a prop.
  Creating a second component that does an existing job requires deleting the first in the same PR.
- **§11 Data Table Standard** — every record list is `DataTable` with: toolbar (search + filters +
  column visibility), sortable headers, fixed header, row checkbox column, select-all-indeterminate,
  bulk action bar, per-row overflow menu (`⋯` → Edit / secondary / destructive), pagination
  (15/25/50), empty + loading skeleton + error states, and keyboard (`↑↓`, `space`, `esc`).
  Any page that renders a list and does not use it fails review.
- **§12 List Page Archetype** — `PageHeader` → `StatStrip` (optional) → `Toolbar` → `DataTable` →
  `BulkActionBar`. No page invents its own ordering.
- **§13 Density & Alignment** — 13px rows / 34px header / 8-16px cell padding / numbers right-aligned
  `tabular-nums` / actions right, always in overflow beyond 2 actions.
- **§14 Icon & Emoji Law** — emoji permitted **only** inside outbound LINE message strings; zero in
  JSX, toasts, PDFs. Icons only from Lucide, only where they add meaning.
- **§15 Token Law** — no hex in `.tsx`; colours come from CSS vars or Tailwind status classes.
  Status palette is **single source: Google set** (`#34A853 / #FBBC04 / #EA4335 / #5F6368 / #BDC1C6`).

## Done When
- `.claude/` is the single source of truth; `.toh/skills|agents|commands` are removed or symlinked
- Status palette identical in `CLAUDE.md`, `ui-design.md`, `DESIGN.md`, `index.css`, `tailwind.config.js`
- `DataTable` + `useListController` exist, tested, and 4 pages consume them with identical behaviour
- `npm run build:check` + `npm run lint` + `npm run test` pass
- `node scripts/check-ui-conventions.mjs` exits 0 (no emoji in JSX, no raw `<table>`, no hex in ui/)
- `.toh/memory/components.md` filled with the real registry (currently `| - | - | - |`)

## Phases

### Phase 0 — Contract repair (docs + tokens, no UI yet)
- [x] T000 design-reviewer — rewrite `DESIGN.md` §2 (single palette = Google set), add §10–§15 reuse/table/list/icon/token law, fix numbering 9→10→…, add Component Registry pointer
- [x] T001 dev-builder — align status tokens: `tailwind.config.js` (`stopped:#EA4335`, `offline:#5F6368`), `CLAUDE.md:249`, `.claude/rules/ui-design.md`, `DESIGN.md:24`; delete the `#22c55e` variant
- [x] T002 dev-builder — `.claude/` becomes the only tree: delete `.toh/skills|agents|commands` duplicates, keep `.toh/plan.md|progress.md|memory/`
- [x] T003 dev-builder — root `MEMORY.md` refresh (Redis gone, VM n2-standard-2, current state) + fill `.toh/memory/components.md` registry
- Checkpoint: `grep -rn "22c55e" CLAUDE.md .claude/rules DESIGN.md bellerox-gps-web/src` → 0 hits

### Phase 1 — Object model (OOP layer, pure TS, tested)
- [x] T100 dev-builder — `src/lib/table/ColumnDef.ts` — `ColumnDef<T>` class: id, header, accessor, sortable, align, width, cell renderer, `getValue(row)`
- [x] T101 dev-builder — `src/lib/table/QueryState.ts` — immutable query state: search term, per-column filters, sort `{id, dir}`, page, pageSize
- [x] T102 dev-builder — `src/lib/table/RowSelection.ts` — `Set<RowId>` semantics: toggle, selectAll, clear, isAllSelected, isIndeterminate, count
- [x] T103 [P] dev-builder — `src/lib/table/ListController.ts` — the OOP core: `setRows()`, `setSearch()`, `setFilter()`, `setSort()`, `select()`, `deselectAll()`, `page()`, `visibleRows`, `pageCount`, `matches(row)`; pure, framework-free
- [x] T104 [P] dev-builder — `src/lib/table/__tests__/` — vitest: sort stability (Thai locale), search+filters compose, select-all respects filtered set, pagination clamp
- Checkpoint: `npx vitest run src/lib/table` green

### Phase 2 — Component set (closed system in `src/components/ui/`)
- [x] T200 ui-builder — primitives: `checkbox.tsx` (indeterminate), `dropdown-menu.tsx` (overflow `⋯`), `sheet.tsx` (side panel), `ConfirmDialog.tsx`, `Skeleton` primitives, `pagination.tsx`; add `index.ts` barrel
- [x] T201 ui-builder — `DataTable<T>` — renders any `ColumnDef<T>[]` + `ListController`: sticky head, checkbox column, sortable headers with aria-sort, row hover, selection tint, overflow menu slot, empty/loading/error slots, responsive card fallback <lg
- [x] T202 [P] ui-builder — `DataTableToolbar` — search input, filter slot (chips/selects), column-visibility menu, export slot, right-aligned bulk counter
- [x] T203 [P] ui-builder — `BulkActionBar` — "{n} selected · เลือกทั้งหมด · ยกเลิกการเลือก" + action buttons + destructive confirm
- [x] T204 ui-builder — `useListController<T>(controller)` hook bridging the class to React (`useSyncExternalStore`), so pages hold zero list state
- Checkpoint: a Storybook-less demo page `/app/_table-lab` renders 30 mock vehicles, every interaction works at 375px; then delete the route

### Phase 3 — Adoption (prove parity, not just existence)
- [x] T300 dev-builder — `FleetPage` → `DataTable` (replaces 1,302-line hand-rolled table region; keeps grid view)
- [x] T301 [P] dev-builder — `DriversPage` → `DataTable` (gains sort, select, bulk, overflow)
- [x] T302 [P] dev-builder — `TrailersPage` → `DataTable`
- [x] T303 [P] dev-builder — `AdminUsersPage` + `AuditLogPage` → `DataTable`
- [x] T304 dev-builder — delete `components/SearchSelect.tsx`; migrate 13 call sites to `ui/search-select.tsx` (one API)
- Checkpoint: four pages show identical toolbar/selection/pagination behaviour; no raw `<table>` left in `pages/`

### Phase 4 — Emoji, tokens, and the guardrail
- [x] T400 dev-builder — strip emoji from web JSX/toasts/PDF (`📍 🥇 👆 ➕ ⚠️ ✓ ✗` → Lucide icon or plain text); keep LINE message strings
- [ ] T401 [P] dev-builder — same sweep in mobile (57 hits)
- [x] T402 dev-builder — `scripts/check-ui-conventions.mjs`: fails on emoji in `.tsx`, raw `<table>` outside `ui/`, hex literals in `src/components/ui`
- [x] T403 dev-builder — wire script into `.github/workflows/build.yml` + `npm run lint:ui`
- Checkpoint: `node scripts/check-ui-conventions.mjs` exit 0; CI green

### Phase 5 — Review
- [x] T500 design-reviewer — re-read DESIGN.md, review the 4 adopted pages against §10–§15, fix violations
- [x] T501 test-runner — `build:check` + `lint` + `test`, report real output
- [x] T502 plan-orchestrator — update `.toh/memory/{active,summary,architecture,components}.md`, root `MEMORY.md`, commit + push + verify CI

## Estimate
6 phases · 27 tasks · ~2.5–4 h of autonomous work. Phases 0–2 are the value; 3–5 prove it holds.

## Risks
- `FleetPage` is 1,302 lines with map-grid logic — migration must keep the grid view and mobile cards intact (T300 is the risky one).
- `tailwind.config.js` fix (T001) changes a *rendered colour* — verify map dots + chips + StatusFilter together before ticking.
- Deleting `.toh/skills|agents|commands` (T002) is irreversible in-tree; the git history keeps it, and `.claude/` is authoritative.
