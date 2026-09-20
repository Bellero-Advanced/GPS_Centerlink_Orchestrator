---
active_plan: .toh/plan.md
status: followups_resolved_2026-09-20
next_task: decide on uncommitted CacheMonitor WIP in bellerox-gps-web; continue e2-small monitoring
context: |
  2026-09-17 incident (login/no-data) RESOLVED. 2026-09-20 follow-ups RESOLVED:
  geocode 502 (Longdo key rotate + Worker fallback split + frontend normalise) and
  traccar.xml filter.future=true→86400 (re-enabled whole FilterHandler; 0 WARN after restart).
---

# Active Work

**Status:** ✅ 2026-09-17 incident + 2026-09-20 follow-ups all resolved

**Open follow-ups (in priority order):**

1. ~~Geocode 502~~ ✅ **FIXED 2026-09-20** — Longdo key rotated (b5cd…→b90b…),
   Worker `geocodeHandler` fallback split into independent try/catch (Longdo throw-text
   guard) `infra fa1c204` → deployed `bellerox-gps-proxy` v`bcb498d5`; frontend
   `geocodingService.ts` normalises จ./อ./ต. + guards throw-text `web 8533233`.
   Verified: fresh Thai coords return correct addresses, /geocode no longer 502.
   ⚠️ Anomaly: deployed worker does NOT emit `X-Worker-Version` header although
   `wrangler deployments list` shows v`bcb498d5` active at 100% and geocode returns
   correct data — likely CF custom-domain header-strip or a propagation quirk. Low
   priority (function works); investigate if header ever needed for diagnostics.

2. ~~`filter.future=true`~~ ✅ **FIXED 2026-09-20** — set to `86400` (seconds) in
   live `/opt/bellerox-gps/infrastructure/docker/traccar/traccar.xml` + repo `infra 8869fa3`.
   `docker restart centerlink-traccar` (VM has docker-compose v1, NOT `docker compose`).
   Verified after restart: 0 WARN (was ~184k/day NumberFormatException), 405 positions/3min,
   0 future-dated rows, 0 invalid rows → the whole FilterHandler chain is alive again.
   Backup on VM: `traccar.xml.bak.20260920`. Devices with year-2080 clocks now filtered
   (will show stale instead of fake-future until their clock is fixed).

3. Direct Traccar UI (`traccar.gps.bellerox.com`) is blocked by design (SEC-002).
   Access via IAP tunnel `-L 8082:localhost:8082` or add office IP to nginx allow list.

4. Continue 7-day e2-small monitoring (memory 1.5 GB used / swap 459 MB — tight).

5. **Uncommitted in `bellerox-gps-web`** (NOT mine — pre-existing local WIP, left untouched):
   CacheMonitorPage.tsx, cacheService.ts, CACHE_IMPLEMENTATION_SUMMARY.md, .toh/QUICK-START.md,
   plus edits to App.tsx/useDevices/useReports/traccarService/vite.config/package*.json.
   Ask the user whether to commit or discard before any future `git add -A` there.
