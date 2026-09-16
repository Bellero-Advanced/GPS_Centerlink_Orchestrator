# 🎯 GPS Infrastructure Optimization & Cost Reduction Plan
> **Goal:** ลดต้นทุน GCP 38% พร้อมเพิ่มประสิทธิภาพสำหรับ 500 คัน
> **Current:** e2-standard-4 (4 vCPU/16GB) ~$179/เดือน
> **Target:** e2-standard-2 (2 vCPU/8GB) ~$111/เดือน + เร็วขึ้น 25%

---

## 📊 System Audit Summary

### Current State (Production Reality Check)
| Component | Spec | Cost/mo | Utilization | Status |
|-----------|------|---------|-------------|--------|
| **VM** | e2-standard-4 (4 vCPU, 16GB RAM) | $97 | ~40-50% CPU, ~60% RAM | ⚠️ Over-provisioned |
| **Disk** | 50GB pd-standard | $2 | ~20GB used | ⚠️ Over-provisioned |
| **Egress** | ~2TB/mo (estimate) | $80 | API calls + GPS data | ⚠️ Can optimize |
| **PostgreSQL** | Docker, 2.5GB limit, 1GB shared_buffers | - | ~500 writes/sec | ✅ Good |
| **Traccar JVM** | Docker, 4GB limit, 3GB heap | - | 500 devices active | ⚠️ Heap too large |
| **Redis** | Docker, 192MB limit, 128MB max | - | 500 positions cache | ✅ Good |
| **PgBouncer** | Docker, 64MB | - | Connection pooling | ✅ Good |
| **Nginx** | Docker, 128MB | - | SSL + cache | ✅ Good |
| **Total** | - | **~$179/mo** | - | ⚠️ **38% over-budget** |

### Load Profile Analysis (500 vehicles)
```
GPS Device Traffic (Inbound):
  500 devices × 1 position/10s = 50 writes/sec (peak ~80 writes/sec)
  Daily positions: 500 × 8,640 = 4.32M positions/day
  Monthly storage: 4.32M × 30 × 150 bytes = ~19.4GB/month
  
Frontend API Traffic (Outbound):
  WebSocket (primary): real-time push to ~5-10 concurrent users
  REST polling (fallback): 
    - Positions: every 20-30s per user
    - Devices: every 30-60s per user
    - Reports: on-demand (cached 5min)
  DLT API calls:
    - Green vehicles (moving): every 15s
    - Yellow/Red (idle/offline): every 1min
    - Batch size: 1-10 vehicles per call
  
Database Workload:
  - Write: 50 inserts/sec sustained (low load)
  - Read: ~100-200 queries/sec (mostly indexed lookups)
  - Storage: 90-day retention = 58GB (with indexes ~80GB)
  - Peak load: monthly reports (scan 4M+ rows)
```

**🎯 Key Finding:** 
- CPU ใช้แค่ 40-50% เฉลี่ย → **VM oversized 2×**
- RAM ใช้ ~10GB/16GB → **memory headroom 37%**
- Traccar heap 3GB แต่ใช้จริง ~1.5-2GB → **heap too large**
- API calls ซ้ำซ้อน (polling + WebSocket) → **ลดได้ 30%**

---

## 🏗️ Stack
- **Infrastructure:** GCP Compute Engine asia-southeast1-a
- **Backend:** Docker Compose (Traccar 6.14.5 + PostgreSQL 16 + Redis 7 + PgBouncer + Nginx)
- **Frontend:** React 18 + Vite 5 + React Query (Cloudflare Pages)
- **Monitoring:** Manual (to be automated with Prometheus + Grafana)

---

## 🎯 Optimization Goals

1. **Cost Reduction:** $179/mo → $111/mo (save $68/mo = 38%)
2. **Performance Boost:** API response 25% faster (via caching)
3. **Stability:** 99.5%+ uptime maintained (no regression)
4. **Scalability:** Support 1,000 devices (2× current load)

---

## ✅ Done When
- [ ] VM downsized to e2-standard-2 successfully
- [ ] PostgreSQL + Traccar tuned for 8GB RAM
- [ ] React Query polling reduced (30s minimum)
- [ ] Nginx cache hit rate > 60% for reports
- [ ] Cost verified in GCP billing: < $120/mo by month-end
- [ ] Load test passed: 1,000 devices stable for 1 hour
- [ ] Monitoring dashboard live (Prometheus + Grafana)
- [ ] Documentation updated with new specs
- [ ] Rollback plan documented and tested

---

## 📋 Phases

### Phase 1: Frontend Optimization (No Downtime)
**Duration:** 2-3 hours · **Risk:** Low · **Impact:** -30% API calls, -$20/mo egress

- [ ] T001 `dev-builder` — Optimize React Query polling intervals
  - Files: `bellerox-gps-web/src/hooks/useDevices.ts`, `useTraccarWebSocket.ts`
  - Current state:
    ```typescript
    // positions — PRIMARY real-time source
    refetchInterval: 20_000  // 20s polling
    staleTime: 10_000       // 10s fresh
    
    // devices — metadata only
    refetchInterval: 30_000  // 30s polling
    staleTime: 20_000       // 20s fresh
    ```
  - Changes:
    ```typescript
    // positions — WebSocket is primary, polling is FALLBACK only
    refetchInterval: 30_000  // 30s (was 20s) — less aggressive
    staleTime: 25_000       // 25s (was 10s) — longer cache
    
    // devices — rarely change
    refetchInterval: 60_000  // 60s (was 30s) — half frequency
    staleTime: 50_000       // 50s (was 20s) — 2× cache
    ```
  - Expected: 33% fewer API calls (~100 calls/min → 67 calls/min)
  - Test: WebSocket logs show real-time updates still working
  - **Checkpoint:** `npm run build` passes, WebSocket primary, polling fallback

- [ ] T002 `backend-connector` — Add Nginx cache for reports API
  - Files: `infrastructure/docker/nginx/conf.d/default.conf`
  - Add cache zones:
    ```nginx
    proxy_cache_path /var/cache/nginx/reports levels=1:2 keys_zone=reports_cache:10m max_size=100m inactive=10m;
    
    location /api/reports {
        proxy_cache reports_cache;
        proxy_cache_valid 200 5m;
        proxy_cache_key "$request_uri";
        add_header X-Cache-Status $upstream_cache_status;
        proxy_pass http://traccar:8082;
    }
    
    # DLT batch position reads
    location ~ ^/api/positions\?deviceId= {
        proxy_cache reports_cache;
        proxy_cache_valid 200 10s;
        add_header X-Cache-Status $upstream_cache_status;
        proxy_pass http://traccar:8082;
    }
    ```
  - Expected: 60%+ cache hit rate for reports within 1 hour
  - Test: `curl -I https://api.centerlink.co.th/api/reports/summary?...` twice → 2nd shows `X-Cache-Status: HIT`
  - **Checkpoint:** Nginx reload successful, cache working

- [ ] T003 `backend-connector` — Reduce Redis memory limit
  - Files: `infrastructure/docker/docker-compose.yml`
  - Change:
    ```yaml
    redis:
      command: >
        redis-server
          --maxmemory 64mb  # was 128mb — 500 positions = ~50KB only
    ```
  - Rationale: 500 vehicles × 100 bytes/position = 50KB data + overhead = ~10-15MB used
  - Test: `docker exec centerlink-redis redis-cli INFO memory` → `used_memory_human` < 64MB
  - **Checkpoint:** Redis stable, zero evictions

- [ ] T004 `root-cause-debugger` — Run database optimization
  - Script: `infrastructure/scripts/db-optimize.sh`
  - Actions:
    - Create missing indexes (if any)
    - `VACUUM ANALYZE tc_positions;`
    - `REINDEX INDEX CONCURRENTLY idx_tc_positions_device_fixtime;`
  - Expected: Query planner uses indexes, no seq scans on large tables
  - Test: `EXPLAIN ANALYZE SELECT * FROM tc_positions WHERE deviceId=123 ORDER BY fixtime DESC LIMIT 100;`
  - **Checkpoint:** Dashboard load time < 500ms (was ~800ms)

**Phase 1 Checkpoint:**
✅ API calls reduced 30-35%
✅ Nginx cache hit rate > 50%
✅ No performance regression
✅ Ready for VM resize

---

### Phase 2: VM Resize & Memory Tuning (5-10 min Downtime)
**Duration:** 1-2 hours · **Risk:** Medium · **Impact:** -$47/mo

- [ ] T005 `backend-connector` — Full PostgreSQL backup
  - Script: `infrastructure/scripts/backup.sh`
  - Command:
    ```bash
    ssh bellerox-gps-vm
    cd /opt/centerlink-gps/infrastructure/scripts
    ./backup.sh
    ```
  - Output: `/opt/centerlink-gps/backups/traccar-backup-$(date +%Y%m%d-%H%M%S).sql.gz`
  - Verify: Backup file size > 100MB, contains tc_positions data
  - Upload to GCS (optional): `gsutil cp backup-*.sql.gz gs://bellerox-gps-backups/`
  - **Checkpoint:** Backup verified, can restore if needed

- [ ] T006 `backend-connector` — Update Docker Compose for 8GB RAM
  - Files: `infrastructure/docker/docker-compose.yml`
  - Changes:
    ```yaml
    postgres:
      command: >
        postgres
          -c shared_buffers=512MB          # was 1GB (half)
          -c effective_cache_size=3GB      # was 4GB
          -c max_connections=80            # was 100
          -c work_mem=16MB                 # unchanged
          -c maintenance_work_mem=256MB    # unchanged
      mem_limit: 1500m                     # was 2500m
    
    traccar:
      environment:
        JAVA_OPTS: >
          -Xms256m                         # was 512m (half initial)
          -Xmx2g                           # was 3g (33% smaller)
          -XX:+UseG1GC
          -XX:MaxGCPauseMillis=200
          -XX:G1HeapRegionSize=16m
      mem_limit: 2500m                     # was 4g
    
    pgbouncer:
      environment:
        DEFAULT_POOL_SIZE: 15              # was 20
        MAX_CLIENT_CONN: 80                # was 100
      mem_limit: 64m                       # unchanged
    ```
  - Memory budget (8GB total):
    - OS + Docker: 800MB
    - PostgreSQL: 1500MB
    - Traccar: 2500MB
    - Redis: 64MB
    - PgBouncer: 64MB
    - Nginx: 128MB
    - **Total: 5.1GB used, 2.9GB free (36% headroom)** ✅
  - Test: `docker-compose config` validates
  - **Checkpoint:** Config syntax valid, memory budget adds up

- [ ] T007 `plan-orchestrator` — Resize GCP VM
  - Commands:
    ```bash
    # 1. Stop VM (GPS devices will buffer data)
    gcloud compute instances stop bellerox-gps-vm \
      --zone=asia-southeast1-a
    
    # 2. Change machine type
    gcloud compute instances set-machine-type bellerox-gps-vm \
      --machine-type=e2-standard-2 \
      --zone=asia-southeast1-a
    
    # 3. Start VM
    gcloud compute instances start bellerox-gps-vm \
      --zone=asia-southeast1-a
    
    # 4. Verify
    gcloud compute instances describe bellerox-gps-vm \
      --zone=asia-southeast1-a \
      --format="value(machineType)"
    ```
  - Downtime: ~5-8 minutes
  - GPS devices: Auto-reconnect when Traccar comes back online
  - **Checkpoint:** VM running, SSH accessible, machine type = e2-standard-2

- [ ] T008 `test-runner` — Deploy updated config & restart Docker stack
  - Commands:
    ```bash
    ssh bellerox-gps-vm
    cd /opt/centerlink-gps/infrastructure/docker
    
    # Pull latest config from git (if updated remotely)
    git pull origin main
    
    # Restart with new memory limits
    docker-compose down
    docker-compose up -d
    
    # Watch logs for errors
    docker-compose logs -f --tail=100
    ```
  - Wait for all healthchecks GREEN (~2-3 minutes):
    - PostgreSQL: "database system is ready to accept connections"
    - PgBouncer: process running
    - Redis: PONG response
    - Traccar: "Main [INFO] server version 6.14.5"
    - Nginx: HTTP 200 on health endpoint
  - Verify GPS devices reconnecting: Traccar admin → Devices → check "lastUpdate" timestamps
  - **Checkpoint:** All 6 containers healthy, API responds, GPS data flowing

**Phase 2 Checkpoint:**
✅ VM resized to e2-standard-2
✅ Docker stack stable on 8GB RAM
✅ Memory usage: ~5.5GB/8GB (31% free)
✅ GPS devices reconnected (check Traccar admin)
✅ No data loss (positions still writing)

---

### Phase 3: Load Testing & Validation
**Duration:** 2-3 hours · **Risk:** Low

- [ ] T009 `test-runner` — Simulate 1,000 GPS devices
  - Script: `infrastructure/scripts/load-test-gps-devices.js`
  - Setup:
    ```bash
    cd /Users/macbookaair/Documents/bellerox_workspace/gps_thailand_application
    npm install --prefix infrastructure/scripts
    ```
  - Run:
    ```bash
    TRACCAR_HOST=34.142.244.40 \
    PROTOCOL=gt06 \
    node infrastructure/scripts/load-test-gps-devices.js \
      --devices=1000 \
      --interval=10 \
      --duration=3600
    ```
  - Monitor (SSH to VM):
    ```bash
    # CPU
    top -bn1 | grep "Cpu(s)"
    # Memory
    free -h
    # PostgreSQL connections
    docker exec centerlink-postgres psql -U traccar -c "SELECT count(*) FROM pg_stat_activity;"
    # Traccar logs
    docker logs centerlink-traccar --tail=50 -f
    ```
  - Success criteria:
    - CPU < 70% average
    - Memory < 6.5GB
    - PostgreSQL write latency < 100ms (check Traccar logs)
    - Zero "OutOfMemory" or "Connection refused" errors
  - **Checkpoint:** System stable under 2× load for 1 hour

- [ ] T010 `test-runner` — Stress test frontend users
  - Script: `infrastructure/scripts/load-test-websocket-users.js`
  - Run:
    ```bash
    TRACCAR_URL=https://api.centerlink.co.th \
    TRACCAR_EMAIL=admin@centerlink.co.th \
    TRACCAR_PASSWORD=<password> \
    node infrastructure/scripts/load-test-websocket-users.js \
      --users=10 \
      --duration=300
    ```
  - Monitor:
    - WebSocket connections: `docker exec centerlink-traccar ss -n | grep :8082 | wc -l`
    - Nginx cache hit rate: Check access logs
    - React Query cache: Browser devtools Network tab
  - Success criteria:
    - All users connected successfully
    - WebSocket latency < 500ms
    - No disconnects/errors
  - **Checkpoint:** 10 concurrent users smooth, no lag

- [ ] T011 `ui-builder` — Deploy Prometheus + Grafana monitoring
  - Files: `infrastructure/monitoring/docker-compose.monitoring.yml`
  - Deploy:
    ```bash
    ssh bellerox-gps-vm
    cd /opt/centerlink-gps/infrastructure/monitoring
    docker-compose up -d
    ```
  - Access Grafana: http://34.142.244.40:3000
    - Login: admin / (set password on first login)
    - Add Prometheus datasource: http://prometheus:9090
    - Import dashboard: `grafana/dashboards/gps-performance.json`
  - Verify metrics:
    - CPU/Memory usage
    - PostgreSQL connections
    - Traccar device count
    - HTTP request rate
  - **Checkpoint:** Grafana dashboard live, metrics flowing

**Phase 3 Checkpoint:**
✅ Load test passed (1,000 devices)
✅ Stress test passed (10 users)
✅ Monitoring deployed
✅ Performance baseline recorded

---

### Phase 4: Long-term Optimization
**Duration:** 1-2 hours · **Risk:** Low · **Impact:** +$1/mo savings

- [ ] T012 `backend-connector` — Disk resize evaluation
  - Current: 50GB pd-standard
  - Used: ~20GB (check: `df -h`)
  - Options:
    1. **Shrink to 30GB** → save $0.80/mo (requires snapshot + new disk + partition resize)
    2. **Keep 50GB** → growth buffer, minimal cost
  - Recommendation: Keep 50GB (effort not worth $0.80/mo)
  - **Checkpoint:** Decision documented

- [ ] T013 `dev-builder` — Enable TimescaleDB compression
  - Files: `infrastructure/postgres/init-timescale.sql`
  - SQL:
    ```sql
    -- Convert tc_positions to hypertable (if not already)
    SELECT create_hypertable('tc_positions', 'servertime', 
      chunk_time_interval => INTERVAL '1 day',
      if_not_exists => TRUE
    );
    
    -- Enable compression for data > 7 days old
    ALTER TABLE tc_positions SET (
      timescaledb.compress,
      timescaledb.compress_segmentby = 'deviceid',
      timescaledb.compress_orderby = 'servertime DESC'
    );
    
    SELECT add_compression_policy('tc_positions', INTERVAL '7 days');
    
    -- Retention: auto-drop chunks > 60 days
    SELECT add_retention_policy('tc_positions', INTERVAL '60 days');
    ```
  - Run:
    ```bash
    docker exec -i centerlink-postgres psql -U traccar -d traccar < init-timescale.sql
    ```
  - Expected: 60-70% compression ratio after 1 week
  - Monitor: `SELECT pg_size_pretty(pg_total_relation_size('tc_positions'));`
  - **Checkpoint:** Compression policy active, storage shrinking

- [ ] T014 `plan-orchestrator` — Update documentation
  - Files to update:
    1. `CLAUDE.md` → VM specs section
    2. `.claude/rules/infrastructure.md` → cost table + memory budget
    3. `.toh/memory/infra-real-state-audit.md` → new baseline
    4. `infrastructure/docker/docker-compose.yml` → inline comments
  - Changes:
    - e2-standard-4 → e2-standard-2
    - $179/mo → $111/mo
    - Memory limits updated
  - **Checkpoint:** All docs accurate, git committed

**Phase 4 Checkpoint:**
✅ Disk decision made
✅ TimescaleDB compression enabled
✅ Documentation updated
✅ All changes committed to git

---

### Phase 5: Monitoring & Rollback Readiness
**Duration:** 30 min setup + 7 days observation

- [ ] T015 `plan-orchestrator` — Document rollback procedure
  - File: `infrastructure/ROLLBACK.md`
  - Content:
    ```markdown
    # Rollback to e2-standard-4
    
    ## When to rollback:
    - CPU > 80% sustained for > 30 minutes
    - Memory > 7GB sustained
    - Position write lag > 60 seconds
    - API errors > 5% of requests
    
    ## Rollback steps (< 15 minutes):
    1. Stop VM: `gcloud compute instances stop bellerox-gps-vm --zone=asia-southeast1-a`
    2. Resize: `gcloud compute instances set-machine-type bellerox-gps-vm --machine-type=e2-standard-4 --zone=asia-southeast1-a`
    3. Restore config: `git checkout HEAD~1 infrastructure/docker/docker-compose.yml`
    4. Start VM: `gcloud compute instances start bellerox-gps-vm --zone=asia-southeast1-a`
    5. Deploy: `cd /opt/centerlink-gps && docker-compose up -d`
    6. Verify: Check Grafana metrics + Traccar API
    
    ## Verify rollback:
    - VM machine type: `gcloud compute instances describe bellerox-gps-vm --format="value(machineType)"`
    - Should show: e2-standard-4
    ```
  - **Checkpoint:** Rollback doc created

- [ ] T016 `plan-orchestrator` — Set up cost & performance alerts
  - GCP Console → Billing → Budgets:
    - **Budget Alert 1:** Monthly forecast > $130 → Email alert
    - **Budget Alert 2:** Actual spend > $140 → Email + Slack
  - Grafana → Alerting:
    - **CPU Alert:** avg > 80% for 10 min → Slack
    - **Memory Alert:** usage > 7GB for 5 min → Slack
    - **API Error Alert:** error rate > 5% for 5 min → Slack
  - **Checkpoint:** Alerts configured, test notifications sent

- [ ] T017 `test-runner` — 7-day monitoring & validation
  - Daily checks (automated via Grafana):
    - GCP billing: trending toward $111/mo?
    - CPU average: < 50%
    - Memory average: < 75% (6GB)
    - Position write rate: ~50/sec
    - API error rate: < 1%
  - Manual checks (day 1, 3, 7):
    - User feedback: Any complaints?
    - Traccar admin: All devices online?
    - PostgreSQL slow query log: Any new slow queries?
  - **Checkpoint:** 7 days stable, cost target met

**Phase 5 Checkpoint:**
✅ Rollback plan ready and tested
✅ Alerts configured
✅ 7-day stability confirmed
✅ Cost savings verified ($68/mo)
✅ Project complete 🎉

---

## 📊 Expected Outcomes

### Cost Savings (Monthly)
| Item | Before | After | Savings |
|------|--------|-------|---------|
| VM (e2-standard-4 → e2-standard-2) | $97 | $50 | **$47** |
| Egress (API call reduction 30%) | $80 | $60 | **$20** |
| Disk (keep 50GB) | $2 | $2 | $0 |
| **Total** | **$179** | **$112** | **$67/mo** |

**Annual savings: $804** 💰

### Performance Improvements
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| API calls/minute | ~300 | ~200 | **-33%** ↓ |
| Dashboard load time | 800ms | 500ms | **-37%** ↓ |
| Report cache hit rate | 0% | 60%+ | **+60%** ↑ |
| Memory headroom | 20% | 31% | **+11%** ↑ |

### Scalability
- **Current capacity:** 500 devices (50% CPU, 60% RAM)
- **After optimization:** 1,000 devices (70% CPU, 75% RAM) — **2× headroom**
- **Max tested:** 1,500 devices stable → then upgrade to e2-standard-4

---

## 🚨 Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| VM too small for peak | Low | High | ✅ Load test 2× capacity first (T009) |
| Memory OOM during reports | Low | Medium | ✅ Swap enabled, Grafana alerts |
| GPS devices lose data | Very Low | Low | ✅ Traccar buffers 5min, auto-reconnect |
| Database slow after downsize | Low | Medium | ✅ Indexes optimized first (T004) |
| Rollback fails | Very Low | High | ✅ Backup tested (T005), rollback doc (T015) |

---

## 📝 Implementation Notes

### Best Time to Execute:
- **Phase 1:** Anytime (no downtime)
- **Phase 2:** Weekend night 2-4 AM Bangkok time (Sat/Sun)
- **Downtime window:** 5-10 minutes (GPS devices will buffer, auto-reconnect)

### Communication Plan:
- 24h before Phase 2: Email fleet managers "5-10 min maintenance window"
- During downtime: Status page update (if available)
- After complete: Send summary email with performance improvements

### Success Metrics:
- Cost < $120/mo by end of first month ✅
- No user complaints about speed/reliability ✅
- Load test passed ✅
- Monitoring dashboard deployed ✅

---

**Status:** approved  
**Approved:** 2026-09-16 by user — full autonomy granted  
**Started:** 2026-09-16  
**Completed:** N/A
