---
active_plan: .toh/plan.md
status: incident_resolved_2026-09-17
next_task: Renew Longdo API key + fix geocode Worker fallback; decide on traccar.xml filter.future
context: |
  2026-09-17 09:50 ICT incident: "app ไม่มีข้อมูล / Traccar เข้าไม่ได้"

  ROOT CAUSE (frontend + nginx):
  - Frontend bundle was built with VITE_TRACCAR_API_URL=https://traccar.gps.bellerox.com
    (GitHub secret set 2026-07-13) → browser called the origin VM directly.
  - nginx.conf has SEC-002 (allow Cloudflare IPs only, deny all) since 2026-08-23 on disk,
    but the running container kept the old config until `docker compose up -d`
    recreated every container on 2026-09-16 17:09 ICT (part of the e2-small downsize).
  - After recreate: every /api/session from browsers → 403 + CORS error → login failed,
    tabs opened before the recreate still worked (old bundle in memory) → looked intermittent.

  FIX (deployed, verified):
  - GH secrets VITE_TRACCAR_API_URL=https://api.centerlink.co.th,
    VITE_TRACCAR_WS_URL=wss://api.centerlink.co.th/api/socket
  - src/lib/traccarApiBase.ts: resolveTraccarApiBase() accepts only Cloudflare-fronted
    hosts, else falls back to api.centerlink.co.th (traccarClient + adminTraccarClient)
  - bellerox-gps-web commit 03f10bf → CI run 35178445208 green → bundle index-5HKFKT4h
  - Verified in browser: login admin_gpsthailand → /app/map shows 221 vehicles.

  NOT CHANGED (VM/Traccar/nginx untouched): e2-small is healthy — no OOM, GPS ingest
  steady 7k positions/h, 88 devices/day (same as previous week).
---

# Active Work

**Status:** ✅ Incident resolved 2026-09-17 10:35 ICT — app + login back to normal

**Open follow-ups (in priority order):**

1. **Geocode 502** (`/geocode` via Worker) — Longdo key `b5cd…9dcb` is invalid
   (`Geo Service API Key Error`, returned as text with HTTP 200). Worker
   `geocodeHandler` wraps Longdo + Nominatim in ONE try/catch → Longdo's
   `res.json()` throw skips the Nominatim fallback → 502 for every address.
   Fix: renew Longdo key (`wrangler secret put LONGDO_API_KEY`) AND give the
   Longdo call its own try/catch. ⚠️ Deployed Worker does not emit
   `X-Worker-Version` although repo source does → deployed source ≠ git;
   diff/download before deploying from repo.

2. **traccar.xml `filter.future=true`** (should be seconds) → NumberFormatException
   on ~every position (~190k WARN/day, FilterHandler:77). Traccar keeps saving the
   position but the whole FilterHandler is bypassed → invalid (17k/24h) and
   future-dated positions (28.8k/24h, some year 2080) reach the DB and the live
   map. Fix = set a numeric value (e.g. 86400) in
   `/opt/bellerox-gps/infrastructure/docker/traccar/traccar.xml` + restart
   Traccar (~30–60 s ingest gap). Decide first: devices with clock drift will then
   show stale instead of fake-future times.

3. Direct Traccar UI (`traccar.gps.bellerox.com`) is blocked by design (SEC-002).
   Access via IAP tunnel `-L 8082:localhost:8082` or add office IP to nginx allow list.

4. Continue 7-day e2-small monitoring (memory 1.5 GB used / swap 459 MB — tight).
