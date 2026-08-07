# Security Audit Report — Bellerox GPS Infrastructure
**Date:** 2026-08-01  
**Auditor:** /toh-protect  
**Scope:** infrastructure/ · cloudflare/workers/ · bellerox-gps-web/src/

---

## EXECUTIVE SUMMARY

| | |
|---|---|
| **Risk Level** | 🔴 HIGH |
| **Files Scanned** | docker-compose.yml · traccar.xml · nginx.conf · traccar-proxy.ts · traccarClient.ts · authStore.ts |
| **Issues Found** | **14 total** — 2 CRITICAL · 4 HIGH · 6 MEDIUM · 2 LOW |
| **Deploy Status** | ⛔ Fix 2 CRITICAL + HIGH-3 before next production deploy |

---

## CRITICAL — Must fix before deploy

### [SEC-001] Hardcoded database password in traccar.xml
- **File:** `infrastructure/docker/traccar/traccar.xml:15`
- **Evidence:** `<entry key='database.password'>ad8f805b575d47fd93698ec525ac53e9</entry>`
- **Risk:** If this file is committed to git, the password is permanently in version history. Any developer with repo access has the DB password.
- **Fix:**
  ```bash
  # 1. Add traccar.xml to .gitignore (or only commit a traccar.xml.template)
  echo "infrastructure/docker/traccar/traccar.xml" >> .gitignore

  # 2. On VM, rotate the password:
  docker exec centerlink-postgres psql -U traccar -d traccar \
    -c "ALTER USER traccar PASSWORD '$(openssl rand -hex 24)';"
  # Update traccar.xml + .env on VM to match, then:
  docker restart centerlink-traccar
  ```

---

### [SEC-002] DLT government API proxied over plain HTTP
- **File:** `infrastructure/cloudflare/workers/traccar-proxy.ts:13`
- **Evidence:** `const DLT_GPS_ORIGIN = 'http://gpsservice.dlt.go.th';`
- **Risk:** Thai government DLT GPS compliance data (vehicle registrations, license plates, routes) transmitted in plaintext between Cloudflare's edge and DLT's server. MITM interception possible on the CF→DLT hop.
- **Fix:**
  ```typescript
  // Change line 13:
  const DLT_GPS_ORIGIN = 'https://gpsservice.dlt.go.th';
  // If DLT server doesn't support HTTPS on this endpoint, add a note comment
  // and monitor for HTTPS availability. Test: curl -I https://gpsservice.dlt.go.th/gps/
  ```

---

## HIGH — Should fix before deploy

### [SEC-003] Traccar CORS origin mismatch — WebSocket will fail
- **File:** `infrastructure/docker/traccar/traccar.xml:23`
- **Evidence:** `<entry key='web.origin'>https://gps.centerlink.co.th</entry>`
- **Risk:** The real production frontend is `gps.bellerox.com`. Traccar's built-in CORS validation rejects direct requests and WebSocket upgrades from any other origin. If any WebSocket connection bypasses the Cloudflare Worker (e.g., fallback, direct debug), it will fail with a CORS error. The Cloudflare Worker (`traccar-proxy.ts`) does not proxy WebSocket upgrades — it uses standard `fetch()` only — so WebSocket connections from the frontend currently go **directly to traccar.gps.bellerox.com**, making this mismatch an active problem.
- **Fix:**
  ```xml
  <!-- traccar.xml — accept both domains during migration, then clean up -->
  <entry key='web.origin'>https://gps.bellerox.com,https://gps.centerlink.co.th</entry>
  ```
  Long-term: add WebSocket proxy support to the Cloudflare Worker using `WebSocketPair`.

---

### [SEC-004] Overly broad subdomain wildcard in CORS allowlist
- **File:** `infrastructure/cloudflare/workers/traccar-proxy.ts:26-28`
- **Evidence:**
  ```typescript
  if (origin.endsWith('.centerlink.co.th')) return true;
  if (origin.endsWith('.bellerox-gps.pages.dev')) return true;
  if (origin.endsWith('.centerlink-gps.pages.dev')) return true;
  ```
- **Risk:** Any subdomain — including `evil.centerlink.co.th` or a subdomain takeover — passes the CORS check. Combined with `Allow-Credentials: true`, this allows any such origin to make authenticated API requests on behalf of a logged-in user.
- **Fix:**
  ```typescript
  // Use an explicit allowlist only — remove wildcard subdomain checks
  const ALLOWED_ORIGINS = [
    'https://gps.centerlink.co.th',
    'https://gps.bellerox.com',
    'https://centerlink-gps.pages.dev',
    'https://bellerox-gps.pages.dev',
    // dev previews via explicit CF Pages preview URLs if needed
  ];
  // Remove lines 26-28 (endsWith checks). Keep localhost check for local dev.
  ```

---

### [SEC-005] Internal error detail exposed in Cloudflare Worker 502 response
- **File:** `infrastructure/cloudflare/workers/traccar-proxy.ts:83`
- **Evidence:** `JSON.stringify({ error: 'DLT upstream unavailable', detail: String(err) })`
- **Risk:** `String(err)` can expose internal hostnames, network topology, stack traces, or upstream error messages to any API consumer.
- **Fix:**
  ```typescript
  // Line 83 — sanitize the error
  return new Response(
    JSON.stringify({ error: 'DLT upstream unavailable' }),  // no detail field
    { status: 502, headers: { 'Content-Type': 'application/json', ...cors, ...vHeader } },
  );
  // Log detail server-side only:
  console.error('[DLT proxy error]', String(err));
  ```

---

### [SEC-006] Redis has no authentication password
- **File:** `infrastructure/docker/docker-compose.yml:116-124`
- **Evidence:** `redis-server --maxmemory 128mb ...` — no `--requirepass` flag
- **Risk:** Any container on the `centerlink-internal` network can read/write/flush Redis without credentials. Redis stores live GPS positions (pub/sub). An RCE in Traccar or any future container could dump or poison real-time vehicle data.
- **Fix:**
  ```yaml
  # docker-compose.yml — add requirepass
  command: >
    redis-server
      --requirepass ${REDIS_PASSWORD}
      --maxmemory 128mb
      ...
  ```
  Add `REDIS_PASSWORD` to `.env`. Configure Traccar to use the password if it connects to Redis directly (check traccar.xml `store.redis` settings).

---

## MEDIUM — Fix when possible

### [SEC-007] Basic auth token (base64) persisted to localStorage
- **File:** `bellerox-gps-web/src/stores/authStore.ts:83`
- **Evidence:** `const _basic = btoa(\`${email}:${password}\`)`  — this `_basic` value is included in Zustand's `partialize()` output and persisted to `localStorage`.
- **Risk:** Base64 is not encryption — it's trivially reversible. If the app ever has an XSS vulnerability (a third-party script, a compromised npm package), `localStorage` is fully accessible and the user's credentials are exposed in plaintext.
- **Mitigation (no full fix required now):** Document the accepted risk. For higher-security customers, consider a server-side session cookie (HttpOnly, Secure, SameSite=Strict) instead of localStorage tokens. The current approach is equivalent to other Basic-auth SaaS apps — acceptable with a strong CSP (see SEC-009).

---

### [SEC-008] Unpinned Docker image tags
- **File:** `infrastructure/docker/docker-compose.yml:77, 143, 244`
- **Evidence:** `edoburu/pgbouncer:latest`, `traccar/traccar:6`, `certbot/certbot:latest`
- **Risk:** `docker compose pull` on the VM could silently upgrade to a breaking or compromised image version.
- **Fix:** Pin to a specific digest or version tag:
  ```yaml
  image: edoburu/pgbouncer:1.22.1       # was :latest
  image: traccar/traccar:6.14.5         # was :6
  image: certbot/certbot:v2.11.0        # was :latest
  ```

---

### [SEC-009] Missing Strict-Transport-Security (HSTS) header
- **File:** `infrastructure/docker/nginx/nginx.conf` — absent
- **Risk:** No HSTS means browsers don't enforce HTTPS-only connections. A user who types `http://traccar.gps.bellerox.com` gets redirected, but there's a brief window for SSL-stripping attacks.
- **Fix:** Add to the `ssl_server` block in nginx.conf:
  ```nginx
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
  ```

---

### [SEC-010] Missing Content-Security-Policy header
- **File:** nginx.conf (server-level headers) + `bellerox-gps-web/` (app-level)
- **Risk:** No CSP means a successful XSS attack can exfiltrate data to any origin. This is the primary mitigation against the localStorage credential exposure (SEC-007).
- **Fix:** Add a CSP header in nginx.conf (for the Traccar admin UI), and in the web app's Vite/Cloudflare Pages config:
  ```nginx
  add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; connect-src 'self' wss://api.gps.bellerox.com https://api.gps.bellerox.com; img-src 'self' data: https://*.tile.openstreetmap.org; style-src 'self' 'unsafe-inline';" always;
  ```

---

### [SEC-011] ssl_stapling enabled without resolver directive
- **File:** `infrastructure/docker/nginx/nginx.conf:115-116`
- **Evidence:** `ssl_stapling on; ssl_stapling_verify on;` — no `resolver` directive in server block
- **Risk:** OCSP stapling silently fails (confirmed prod warning). nginx can't resolve the OCSP responder address. Minor performance impact; not a security vulnerability but means clients can't verify certificate revocation status quickly.
- **Fix:**
  ```nginx
  ssl_stapling        on;
  ssl_stapling_verify on;
  resolver            8.8.8.8 1.1.1.1 valid=300s;   # add this line
  resolver_timeout    5s;
  ```

---

### [SEC-012] Port range 6001-6500 exposed to internet
- **File:** `infrastructure/docker/docker-compose.yml:182`
- **Evidence:** `- "6001-6500:6001-6500"` — 500 ports published to 0.0.0.0
- **Risk:** These are reserved for future multi-tenant device port isolation. If that feature isn't actively used, 500 ports are unnecessarily open to internet scanners. Each open port is an attack surface.
- **Fix:** Remove the range until the multi-tenant feature is actually deployed:
  ```yaml
  # Comment out or remove:
  # - "6001-6500:6001-6500"
  ```
  Add GCP firewall rule to block 6001-6500 in the meantime.

---

## LOW — Informational

### [SEC-013] JVM heap dump stored in log volume on OOM
- **File:** `infrastructure/docker/docker-compose.yml:196`
- **Evidence:** `-XX:HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/traccar/logs/heap-dump.hprof`
- **Risk:** A heap dump contains a snapshot of all objects in JVM memory at crash time — this can include decrypted credentials, session tokens, vehicle position data, and user PII. The `traccar_logs` volume persists on the VM.
- **Mitigation:** Keep the flag (it's essential for debugging OOM crashes) but set a post-dump alert to notify the team and rotate/delete the dump after analysis. Restrict log volume access: `chmod 700 /var/lib/docker/volumes/docker_traccar_logs`.

---

### [SEC-014] Fallback API URL hardcoded to old domain in traccarClient.ts
- **File:** `bellerox-gps-web/src/lib/traccarClient.ts:14`
- **Evidence:** `baseURL: import.meta.env.VITE_TRACCAR_API_URL || 'https://api.centerlink.co.th'`
- **Risk:** If `VITE_TRACCAR_API_URL` is not set in a build, the app silently falls back to the old domain `api.centerlink.co.th`, which may not exist or could be owned by someone else in the future.
- **Fix:**
  ```typescript
  // Fail loudly if the env var is missing — never silently fall back to a hardcoded URL
  const TRACCAR_API_URL = import.meta.env.VITE_TRACCAR_API_URL;
  if (!TRACCAR_API_URL) throw new Error('VITE_TRACCAR_API_URL is not set');
  ```

---

## DEPENDENCY AUDIT

```
bellerox-gps-web: npm audit not run in this session (no Node env available)
Action: run  cd bellerox-gps-web && npm audit  and fix HIGH+ findings
```

---

## SECURITY HEADERS SUMMARY (nginx.conf)

| Header | Status |
|--------|--------|
| `X-Frame-Options: SAMEORIGIN` | ✅ Present |
| `X-Content-Type-Options: nosniff` | ✅ Present |
| `X-XSS-Protection: 1; mode=block` | ✅ Present |
| `Referrer-Policy` | ✅ Present |
| `Strict-Transport-Security (HSTS)` | ❌ Missing — SEC-009 |
| `Content-Security-Policy` | ❌ Missing — SEC-010 |
| `Permissions-Policy` | ℹ️ Not set (nice-to-have) |

---

## REMEDIATION PRIORITY ORDER

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| 1 🔴 | SEC-001 Hardcoded DB password | 15 min | Prevents credential exposure in git |
| 2 🔴 | SEC-002 DLT plain HTTP | 2 min | Encrypts govt compliance data |
| 3 🟠 | SEC-003 Traccar web.origin mismatch | 5 min | Fixes WebSocket CORS for prod domain |
| 4 🟠 | SEC-004 CORS wildcard subdomains | 10 min | Closes auth bypass via subdomain |
| 5 🟠 | SEC-005 Error detail leakage | 2 min | Hides internal topology |
| 6 🟠 | SEC-006 Redis no password | 20 min | Defense-in-depth for position cache |
| 7 🟡 | SEC-009 Missing HSTS | 2 min | Enforce HTTPS |
| 8 🟡 | SEC-010 Missing CSP | 30 min | XSS mitigation |
| 9 🟡 | SEC-008 Unpinned images | 15 min | Supply chain protection |
| 10 🟡 | SEC-011 ssl_stapling resolver | 3 min | Fix nginx warning |
| 11 🟡 | SEC-012 Port range 6001-6500 | 5 min | Reduce attack surface |
| 12 🟢 | SEC-014 Fallback URL | 3 min | Fail-safe build |
| 13 🟢 | SEC-007 localStorage token | — | Accept risk + document |
| 14 🟢 | SEC-013 Heap dump | — | Monitor + restrict permissions |
