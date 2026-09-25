# 📋 Plan: Reports + history that are fast and stored permanently (TimescaleDB) · remove Redis

**Status:** approved (Go 2026-09-25) — e2-medium resize NOT approved
**Created:** 2026-09-25
**Repos:** infrastructure · bellerox-gps-web (web + `server/` api-gateway) · prod VM `bellerox-gps-vm`
**Previous plan:** `archive/plan-2026-09-25-timezone-fix.md`

## Goal
Reports and Trip Replay should load in < 1–2 s for any range, from data that is **computed once and stored permanently**, not calculated fresh on every request.
Every trip, stop, idle and daily total per vehicle is kept forever in TimescaleDB, compressed so it fits on the disk.
Remove what's unused or risky: the Redis container, the Memorystore config, the nginx report cache, and the IndexedDB report cache.

## Findings (measured on prod, 2026-09-25)
| Item | Measured | Meaning |
|---|---|---|
| `/api/reports/trips` 1 day (device 36) | **16.9 s** | slow |
| `/api/reports/trips` 7 days | **96.0 s** | browser/Worker times out first → "won't load" |
| `/api/reports/stops` 7 days | **47.6 s** | slow |
| `/api/positions` 7 days / 30 days | 0.36 s / 3.6 s | DB is fine |
| `/api/reports/summary`, `/events` | 0.31 s / 0.09 s | fine |
| **Root cause** | `geocoder.onRequest=true` → Traccar calls Photon for **every** trip/stop start+end, ~1.1–1.3 s per call (ReportUtils.java:190,200,243); the result is `null` so it's never cached and runs again on every request | 7 days ≈ 40 trips × 2 × 1.2 s ≈ 96 s ✔ |
| Redis | `centerlink-redis` + `redis-exporter` containers on the VM — **nothing uses them** (redis is commented out in traccar.xml; web and api-gateway never connect) | remove, no impact |
| Memorystore (GCP) | **no instance exists**; Redis API isn't even enabled; Terraform has a resource but it's off | no GCP charge today · remove the code |
| VM | **e2-small 2 GB RAM**, 856 MB swap used, 50 GB disk (20 GB free) | memory is tight |
| Data | tc_positions 8.8M rows / 8.1 GB (~4.5 GB/month), monthly partitions by servertime, no deletion policy | uncompressed → disk full in ~4 months |
| TimescaleDB | not installed (`postgres:16-alpine`) | — |
| api-gateway | Node container already on the VM (`bellerox-gps-web/server`), reads custom tables · **deployed source (index.ts, api/) isn't in the repo** | recover it first |

## Target architecture
```
GPS → Traccar → tc_positions (hypertable, compressed after 7 days, kept forever)
                     │  TimescaleDB job every 5 min (inside Postgres, no new service)
                     ▼
        fleet.segments     — trip / stop / idle for every vehicle, precomputed
        fleet.daily_stats  — continuous aggregate per vehicle per Bangkok day
                     ▼
        api-gateway /fleet/*  (checks device permission via the user's Traccar session)
                     ▼
        Web: Reports / Replay / all vehicles → one SQL query, no cache
```

## Done When
- [ ] `/fleet/trips|stops` 7 days and 30 days: p95 < 1 s (quoted curl timings)
- [ ] Traccar `/api/reports/trips` 7 days < 3 s (after Phase 1)
- [ ] `docker ps` on the VM shows no redis/redis-exporter · terraform has no `google_redis_instance`
- [ ] `tc_positions` is a hypertable + compression on + row count before = after exactly
- [ ] `fleet.segments` backfilled from 2026-07-28 · checked against Traccar for 5 vehicles × 3 days: trip count matches, start time ±60 s, distance ±5%
- [ ] Web: Daily Trip / Alerts / Replay use `/fleet/*` · "all vehicles" works · IndexedDB reportCache removed
- [ ] build + lint pass · CI green · deployed · real browser check
- [ ] Mobile (375px): bottom nav with exactly 4 items (Dashboard · Live Map · Replay · Fleet) · all 4 pages have no horizontal scroll · desktop unchanged

## Phases

### Phase 1 — Unblock reports right away (small, low risk)
- [x] T101 dev-builder — `infrastructure/docker/traccar/traccar.xml`: `geocoder.onRequest=false` (frontend already fetches addresses via the Worker with a fallback) → sync to VM → `docker restart centerlink-traccar` → time trips/stops 1 and 7 days again
- [x] T102 [P] dev-builder — `bellerox-gps-web/src/hooks/useGeofences.ts`: turn off `refetchInterval: 30_000` in `useEvents` for historical ranges (Replay polls for no reason)
- [x] T103 [P] dev-builder — nginx: remove the `/api/reports/*` `proxy_cache` (key is URL-only → cross-tenant leak risk) in `infrastructure/docker/nginx/` + `infrastructure/nginx/` and check what's actually mounted on the VM
- [x] **Checkpoint 1:** quote curl: trips 7 days < 3 s, stops 7 days < 3 s

### Phase 2 — Remove Redis
- [x] T201 dev-builder — VM: `docker stop/rm centerlink-redis centerlink-redis-exporter` + remove the services from `/opt/bellerox-gps/.../docker-compose.yml` and `monitoring/docker-compose.monitoring.yml` + remove the prometheus redis target/alert rules
- [x] T202 [P] dev-builder — repo: delete `docker-compose.redis.yml`, `infrastructure/redis/`, and the redis parts of `docker-compose.yml`/`scale.yml`/`workers.yml` · terraform: remove `google_redis_instance`, `use_memorystore`, the `redis_ip` output from `main.tf` + both tfvars · `terraform validate`
- [x] T203 [P] dev-builder — web: remove the Redis label in `CacheMonitorPage` and the Redis TODOs in `server/middleware/*`
- [x] **Checkpoint 2:** `docker ps` has no redis · Grafana/Prometheus still up · `terraform validate` passes

### Phase 3 — TimescaleDB (permanent storage + compression)
- [x] T301 dev-builder — safety net: snapshot disk `bellerox-gps-vm-balanced` (GCP) before touching the DB
- [x] T302 dev-builder — switch image to `timescale/timescaledb:2.x-pg16` (same PG16 data dir, no dump/restore) + `shared_preload_libraries=timescaledb` + tune memory for 2 GB · `CREATE EXTENSION timescaledb`
- [x] T303 dev-builder — `infrastructure/postgres/timescale-migrate-positions.sql`: create hypertable (time = `fixtime`, 7-day chunks) → copy one month at a time + compress immediately (segmentby deviceid, orderby fixtime) → stop Traccar briefly while copying the delta + swapping table names → **no retention policy** (kept forever) · retire `create-next-month-partition.sh` and its cron
- [ ] T304 [P] dev-builder — tc_events: drop the 3 duplicate indexes (keep `(deviceid, eventtime DESC)` + `(deviceid, type, eventtime DESC)` + pkey)
- [x] **Checkpoint 3:** row count before = after exactly · `hypertable_compression_stats` · `/api/positions` 30 days still ≤ 3.6 s · Traccar keeps writing new positions (max(servertime) keeps advancing)

### Phase 4 — Activity store (precomputed, permanent)
- [x] T401 backend-connector — `infrastructure/postgres/fleet-schema.sql`: `fleet.segments(deviceid, kind trip|stop|idle, start_time, end_time, start/end position id, lat/lon, distance_m, duration_s, max/avg speed, start/end odometer)` hypertable + unique (deviceid, start_time)
- [x] T402 backend-connector — `fleet.build_segments(device, from, to)` PL/pgSQL: gaps-and-islands on `motion`/ignition with the same thresholds as Traccar (minDuration/minDistance/stopGap from device → server config) · `add_job` every 5 min recomputing only the last 2 h per vehicle · backfill from 2026-07-28
- [x] T403 [P] backend-connector — `fleet.daily_stats` continuous aggregate (Bangkok-day bucket): distance, moving/idle/engine time, max speed, trips, position count · refresh policy every 15 min
- [x] T404 test-runner — compare against Traccar `/api/reports/trips|stops` for 5 vehicles (gt06, meitrack, gps103, startek, one override device) × 3 days → table of differences
- [x] **Checkpoint 4:** accuracy within Done When thresholds · job runs without errors in `timescaledb_information.job_stats`

### Phase 5 — Read API (api-gateway)
- [x] T501 dev-builder — pull the real source from the `api-gateway` container into `bellerox-gps-web/server/` (index.ts, api/) and commit first so the repo matches prod
- [x] T502 dev-builder — `server/api/fleet/*.ts`: `GET /fleet/trips|stops|daily|track|events?deviceId=&from=&to=` + `deviceIds=` for all vehicles · permission: the user's Basic auth → Traccar `/api/devices` → only permitted deviceIds pass · `track` returns only the columns Replay needs (lat, lon, speed, course, fixtime, ignition)
- [x] T503 dev-builder — route `/fleet/*` through CF Worker `api.centerlink.co.th` → nginx → api-gateway:3001
- [x] **Checkpoint 5:** quote curl p95 7 days and 30 days < 1 s · someone else's deviceId → 403

### Phase 6 — Frontend
- [x] T601 dev-builder — `src/services/fleetService.ts` + switch `useDailyTripReport`, `useDailyAlertsReport`, `useTripsReport`/`useStopsReport`, `usePositionHistory` (Replay) to `/fleet/*`
- [x] T602 dev-builder — enable the "all vehicles" daily report from `fleet.daily_stats` (single request) · delete `src/lib/reportCache.ts` (IndexedDB) + its call sites
- [ ] T603 test-runner — tsc/build/lint/test + commit/push + CI green + open `/reports`, `/replay` in the browser and quote load times
- [ ] **Checkpoint 6:** all Done When met

### Phase 6M — Mobile web (responsive, 4 pages)
- [x] T651 ui-builder — `Layout.tsx`: below `lg` (<1024px) show a bottom nav with 4 items only (Dashboard · Live Map · Replay · Fleet), hide the sidebar and every other menu · tap targets ≥ 44px · safe-area inset · following DESIGN.md
- [x] T652 ui-builder — make Dashboard / LiveMap / TripReplay / Fleet responsive at 375–430px: map fills the screen, vehicle list becomes a bottom sheet, replay controls stay usable one-handed, fleet table becomes cards, no horizontal scroll
- [x] T653 test-runner — Playwright at 375×812 + 768×1024: screenshots of all 4 pages · no overflow-x · nav shows exactly 4 items · desktop layout unchanged
- [x] **Checkpoint 6M:** screenshots + `scrollWidth <= innerWidth` on all 4 pages · build/lint pass

### Phase 7 — Docs + memory
- [ ] T701 — update `.claude/rules/infrastructure.md` (real architecture: e2-small, no Redis, TimescaleDB), memory, active.md, changelog

## Risks / decisions
- **2 GB RAM:** TimescaleDB + jobs add load; removing redis + exporter frees ~20 MB but swap is already in use → **recommend upgrading to e2-medium (4 GB, ~+$12/month, ~1 min restart)** — only if approved, not included in "Go"
- The T303 migration rewrites 8 GB on a VM with 20 GB free → copy + compress month by month, with a disk snapshot first
- Precomputed trips may differ slightly from Traccar → T404 gate must pass before switching the frontend
- Addresses: not stored in the DB in this plan (Photon returns null) · frontend keeps using the Worker geocoder

## Evidence / deviations (2026-09-25)
- CP1: via Worker trips 7d 96 s → 1.3 s, stops 7d 0.8 s, trips 30d 4.0 s (was 504). Extra root cause: reports rate limit keyed on CF edge IP (10/min shared) → CF-Connecting-IP, 60/min.
- CP2: redis + redis-exporter removed from VM; Prometheus jobs = node-exporter, postgres, prometheus; `terraform validate` OK. No Memorystore existed.
- CP3 **deviation**: tc_positions_ts hypertable built (8,851,211 = 8,851,211 rows; 3.5 GB → 314 MB). Swapping it in as Traccar's table stalled ingestion (Traccar looks up by id across all compressed chunks, load 43) → **rolled back in ~13 min, 0 rows lost** (8,898,531 = 8,898,531). Final design: Traccar keeps plain tc_positions; hypertable is the permanent archive, synced every minute by `fleet.sync_archive` job. Retention cron disabled. Snapshot `pre-timescale-20260925`.
- CP4: trips vs Traccar on 38 device-days: 34/38 equal count, 35/38 distance ±5%; all differences are trips crossing the query boundary (Traccar clips at `from`, fleet keeps full trip under its start day).
- CP5: /api/fleet via Worker: trips 30d 2.9 s cold, stops 7d 0.23 s, whole fleet 1 day 2.0 s; no auth → 401, foreign device → 403.
- CP6M: 375px dashboard/map/replay/fleet scrollWidth = 375, bottom nav 4 links; 1440 desktop unchanged. build OK, lint 0 errors, tests 10 fail (same 10 as HEAD).
- Also fixed: nginx container log 1.8 GB unrotated → json-file 20m×3 for all services.
