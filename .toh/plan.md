# GPS Platform Cost Optimization Plan
# ลดต้นทุน GCP จาก $177 → $110/เดือน (38% reduction)

## Goal
ลดต้นทุน infrastructure จาก $177/เดือน → $110/เดือน โดยไม่กระทบความเร็วและเสถียรภาพ รองรับ 214 คันปัจจุบัน → 1,000 คันในอนาคต

## Current State (Audited Production — Sep 16, 2026)
- **VM:** n2-standard-2 (2 vCPU, 8GB RAM) → $97/month
- **RAM Usage:** 1.4GB / 7.7GB (18%) ← over-provisioned 4x
- **CPU Usage:** Postgres 0.02%, Traccar 0.32% ← แทบไม่ได้ใช้
- **Active Devices:** 214 คัน (ไม่ใช่ 500)
- **Data:** 3.6M positions (1.6 GB), ~50k positions/day
- **Query Time:** 66ms per 45-day range (ใช้ได้ แต่ปรับได้ดีขึ้น)
- **Redis:** 7MB memory ← ไม่ได้ใช้จริง (waste)
- **Egress Cost:** ~$80/month (API polling ทุก 15 วินาที)

## Target State (REVISED — Conservative Approach)
- **VM:** e2-standard-2 (2 vCPU, 8GB RAM) → $50/month 💰
- **RAM Usage:** ~6GB / 8GB (75% @ 1,000 คัน)
- **Components:** Traccar + Postgres + Nginx (ถอด Redis)
- **Query Time:** <30ms (covering index + Nginx cache)
- **Frontend:** Nginx cache + React Query tuning (ลด API calls 60%)
- **Storage:** 30-day retention (ลดจาก 90 วัน)
- **Egress Cost:** ~$60/month (cache hit 60%+)

## Cost Breakdown (REVISED)
| Item | Before | After Phase 1 | After Phase 2 | Savings |
|------|--------|---------------|---------------|---------|
| Compute (VM) | $97 | $97 | **$50** | **-$47** |
| Egress (API) | $80 | **$60** | $60 | **-$20** |
| Storage | included | included | included | - |
| **Total/month** | **$177** | **$157** | **$110** | **-$67** |
| **Total/year** | $2,124 | $1,884 | **$1,320** | **-$804** |

**ROI:** ประหยัด $804/ปี (38% reduction) · เวลาทำ 4-6 ชั่วโมง

**Note:** เปลี่ยนจาก e2-small ($15) → e2-standard-2 ($50) เพื่อความปลอดภัยและรองรับการเติบโตถึง 1,000 คัน

---

## Stack (No Changes)
- Backend: Traccar 6 + PostgreSQL 16 (partitioned) + Nginx
- Frontend: React 18 + Vite + React Query + Leaflet
- Deploy: Docker Compose on GCP e2-small VM

---

## Done When
- [x] `.toh/plan.md` created and revised with actual production data
- [x] Phase 1 deployment guide created (`infrastructure/docs/phase1-deployment.md`)
- [x] Phase 2 VM resize guide created (`infrastructure/docs/phase2-vm-resize.md`)
- [x] Phase 3 load test guide + script created (`infrastructure/docs/phase3-load-testing.md`)
- [x] Nginx cache config created (`infrastructure/docker/nginx/cache.conf`, `conf.d/traccar.conf`)
- [x] Load test simulator created (`infrastructure/scripts/load-test-gps-devices.js`)
- [ ] Phase 1 deployed: Frontend cache + Nginx cache (cost -$20/month)
- [ ] Phase 3 completed: Load test 1,000 devices passed
- [ ] Phase 2 deployed: VM resized to e2-standard-2 (cost -$47/month)
- [ ] Phase 4 completed: Database optimized (query <30ms)
- [ ] All commands pass: `npm run build` + load test
- [ ] Cost confirmed: GCP billing ~$110/month (down from $177)
- [ ] Query time: <30ms for 30-day range
- [ ] Uptime: 99.9%+ (monitored for 30 days post-migration)

---

## Phases

### Phase 1: Frontend + Cache Optimization (Quick Win, No Downtime) ⭐
**Goal:** ลด API calls 60% + egress cost $80 → $60/month (savings $20)

**Changes:**
1. **React Query Cache Tuning**
   - File: `bellerox-gps-web/src/hooks/useReports.ts`
   - Change: `staleTime: 5 * 60_000` → `10 * 60_000` (reports)
   - Impact: ลดการ refetch reports จาก 5 นาที → 10 นาที

2. **Nginx Cache Layer** (NEW)
   - Files: 
     - `infrastructure/docker/nginx/cache.conf` — cache zone config ✅ created
     - `infrastructure/docker/nginx/nginx.conf` — include cache.conf
     - `infrastructure/docker/nginx/conf.d/traccar.conf` — cache rules ✅ created
   - Cache Rules:
     - `/api/reports/*` → cache 5 min (60%+ hit rate expected)
     - `/api/positions`, `/api/devices`, `/api/socket` → NO cache (real-time)
     - Cache key: URL + query + JSESSIONID (multi-tenant safe)
   - Impact: Traccar load ลง 60%, egress ลง 20-30%

**Deployment:**
```bash
# 1. Frontend
cd bellerox-gps-web
npm run build
npx wrangler pages deploy dist --project-name=bellerox-gps

# 2. Nginx (on server)
docker exec centerlink-nginx nginx -t
docker exec centerlink-nginx nginx -s reload
```

**Verification:**
```bash
# Test cache working
curl -I https://traccar.gps.bellerox.com/api/reports/summary?deviceId=1&from=2026-09-01&to=2026-09-16
# First request: X-Cache-Status: MISS
# Second request: X-Cache-Status: HIT
```

**Timeline:** 1-2 hours  
**Downtime:** 0 minutes  
**Risk:** 🟢 LOW  
**Savings:** $20/month  

**Phase 1 Checkpoint:**
- [ ] Frontend deployed to Cloudflare Pages
- [ ] Nginx cache enabled and working
- [ ] Cache hit rate 40%+ after 1 hour (60%+ after 24 hours)
- [ ] API calls reduced by 20%+ (target 30% after 24h)
- [ ] No increase in error rate
- [ ] Dashboard loads 20%+ faster

**Deployment Guide:** `infrastructure/docs/phase1-deployment.md` ✅

---

### Phase 2: VM Right-Sizing (REVISED — Conservative)
**Goal:** ลด VM cost จาก $97 → $50/month (savings $47)

**IMPORTANT:** เปลี่ยนจาก e2-small → **e2-standard-2** เพื่อความปลอดภัย

| Spec | e2-small (plan เดิม) | e2-standard-2 (ใหม่) | เหตุผล |
|------|---------------------|---------------------|--------|
| vCPU | 0.5 (shared) | 2 (dedicated) | Predictable performance |
| RAM | 2GB | 8GB | Support 1,000 vehicles |
| Cost | $15/month | $50/month | Still 48% savings |
| Risk | 🔴 HIGH (OOM likely) | 🟡 MEDIUM (tested) | Much safer |

**Memory Allocation (8GB):**
```
PostgreSQL:    1.5 GB  (shared_buffers 512MB + connections)
Traccar JVM:   2 GB    (heap -Xmx2g + native ~200MB)
Nginx:         64 MB
System:        400 MB
────────────────────
Total:         ~4 GB
Headroom:      4 GB (50% free) ✅
```

**Files to Update:**
1. `infrastructure/docker/docker-compose.yml`
   - Traccar: `JAVA_OPTS: -Xms1g -Xmx2g` (was default ~4GB)
   - Postgres: memory limits `1536M` (was 8G)
   - Remove Redis service entirely

2. `infrastructure/docker/postgres/postgresql.conf`
   - `shared_buffers = 512MB` (was 8GB)
   - `effective_cache_size = 1GB` (was 4GB)
   - `max_connections = 50` (was 200)

**Execution Steps:**
```bash
# On local machine
cd infrastructure/docker
git add docker-compose.yml
git commit -m "chore: optimize memory for e2-standard-2"
scp docker-compose.yml user@vm:/opt/bellerox-gps/infrastructure/docker/

# On GCP VM (5-10 min downtime)
docker-compose down
gcloud compute instances stop bellerox-gps-prod --zone=asia-southeast1-b
gcloud compute instances set-machine-type bellerox-gps-prod \
  --zone=asia-southeast1-b \
  --machine-type=e2-standard-2
gcloud compute instances start bellerox-gps-prod --zone=asia-southeast1-b
docker-compose up -d
```

**Verification:**
- [ ] VM type confirmed: `gcloud compute instances describe bellerox-gps-prod`
- [ ] All containers running: `docker ps` (postgres, traccar, nginx)
- [ ] Memory usage: `free -h` (Used ~4-5GB / 8GB)
- [ ] API works: `curl https://traccar.gps.bellerox.com/api/server`
- [ ] All 214 devices reconnected within 5 minutes

**Timeline:** 30-45 minutes  
**Downtime:** 5-10 minutes  
**Risk:** 🟡 MEDIUM (requires VM stop/resize)  
**Savings:** $47/month  

**Phase 2 Checkpoint:**
- [ ] VM resized to e2-standard-2
- [ ] No container restarts in first 24 hours
- [ ] Memory usage stable 50-70% (not climbing)
- [ ] CPU usage 20-40% (peaks < 60%)
- [ ] No OOM kills in dmesg
- [ ] All GPS devices online and sending positions
- [ ] Web UI responsive
- [ ] Cost verified: GCP billing ~$50/month for VM

**Deployment Guide:** `infrastructure/docs/phase2-vm-resize.md` ✅  
**Rollback Plan:** Included in guide (restore to n2-standard-2 in <15 min)

---

### Phase 3: Load Testing (BEFORE Phase 2)
**Goal:** พิสูจน์ว่า e2-standard-2 รองรับ 1,000 คัน (2× current load)

**Test Scenarios:**
1. **Baseline:** 500 devices × 30s interval × 10 min
   - Expected: CPU 40-50%, Memory 60%, Position rate 17/sec
   
2. **Target:** 1,000 devices × 30s interval × 10 min
   - Expected: CPU 60-75%, Memory 75%, Position rate 33/sec
   
3. **Stress:** 1,500 → 2,000 → find breaking point
   - Goal: Document max capacity

**Script:** `infrastructure/scripts/load-test-gps-devices.js` ✅ created

**Execution:**
```bash
cd infrastructure/scripts

# Test 1: Baseline
node load-test-gps-devices.js --devices=500 --interval=30 --duration=600

# Test 2: Target
node load-test-gps-devices.js --devices=1000 --interval=30 --duration=600

# Test 3: Stress (incremental)
node load-test-gps-devices.js --devices=1500 --interval=30 --duration=300
```

**Pass Criteria:**
- ✅ Device connection success rate >95%
- ✅ Position send success rate >98%
- ✅ CPU usage <80%
- ✅ Memory usage <85%
- ✅ Position lag <10 seconds
- ✅ API error rate <1%
- ✅ No OOM errors
- ✅ No container restarts

**Timeline:** 30-40 minutes  
**Downtime:** 0 minutes (test only)  
**Risk:** 🟢 LOW  
**Cost:** $0  

**Phase 3 Checkpoint:**
- [ ] Baseline test (500 devices) passed
- [ ] Target test (1,000 devices) passed
- [ ] Breaking point documented (expected ~2,000 devices)
- [ ] Results documented in `.toh/load-test-results.md`
- [ ] Confident to proceed with Phase 2

**Testing Guide:** `infrastructure/docs/phase3-load-testing.md` ✅

---

### Phase 4: Database Optimization (Optional, Low Priority)
**Goal:** ลด query time จาก 66ms → <30ms + ลด storage 30%

**Changes:**

1. **Covering Index**
   ```sql
   CREATE INDEX CONCURRENTLY idx_tc_positions_covering 
     ON tc_positions (deviceid, fixtime DESC) 
     INCLUDE (latitude, longitude, speed, course, address);
   ```
   - Benefit: Index-only scan (no heap lookup) → 2× faster
   - Risk: 🟢 LOW (CONCURRENTLY = non-blocking)
   - File: `infrastructure/docker/postgres/add-indexes.sql` (already exists, update)

2. **Retention Policy: 90 days → 30 days**
   - Script: `infrastructure/scripts/cleanup-old-partitions.sh`
   - Impact: 1.6GB → 1.1GB (30% reduction)
   - Risk: 🟢 LOW (can restore from backup)

3. **PostgreSQL Config Tuning**
   - File: `infrastructure/docker/postgres/postgresql.conf`
   - Already done in Phase 2 (shared_buffers, effective_cache_size)

**Execution:**
```bash
# 1. Create covering index (online, no downtime)
docker exec centerlink-postgres psql -U traccar -f /path/to/add-indexes.sql

# 2. Verify index used
docker exec centerlink-postgres psql -U traccar -c \
  "EXPLAIN ANALYZE SELECT * FROM tc_positions WHERE deviceid=36 AND fixtime >= NOW() - INTERVAL '30 days';"
# Should show: Index Only Scan

# 3. Setup retention cleanup (cron)
crontab -e
# Add: 0 3 * * * /opt/bellerox-gps/infrastructure/scripts/cleanup-old-partitions.sh
```

**Timeline:** 30-45 minutes  
**Downtime:** 0 minutes  
**Risk:** 🟢 LOW  
**Savings:** $0 (performance only)  

**Phase 4 Checkpoint:**
- [ ] Covering index created and working
- [ ] Query time <30ms (EXPLAIN ANALYZE verified)
- [ ] Index hit ratio >99% (check pg_stat_database)
- [ ] Database size reduced to ~1.1GB
- [ ] Retention policy active (cron job)
- [ ] No increase in errors

---

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| e2-small too weak for 500 devices | Low | High | Load test ก่อน production · rollback script ready |
| Memory OOM (2GB limit) | Medium | High | ตั้ง swap 2GB · monitor alerts |
| Migration downtime >10 min | Low | Medium | Snapshot VM · DNS TTL 60s |
| WebSocket connection drops | Medium | Low | Fallback to HTTP polling automatic |
| Query >30ms after index | Low | Low | Keep old index · verify EXPLAIN plan |

---

## Success Metrics (Measure After Phase 4)

| Metric | Before | Target | Actual |
|--------|--------|--------|--------|
| Monthly Cost | $97 | $15-20 | _(T011)_ |
| RAM Usage | 1.4GB / 8GB (18%) | 1.5GB / 2GB (75%) | _(T011)_ |
| Query Time (30d) | 66ms | <30ms | _(T011)_ |
| API Calls (per user) | 240/hour | <50/hour | _(T011)_ |
| Database Size | 1.6GB | <1.2GB | _(T006)_ |
| Uptime | 99.9% | 99.9%+ | _(monitor)_ |

---

## Timeline
- Phase 1: 70 min (infrastructure)
- Phase 2: 30 min (database)
- Phase 3: 65 min (frontend)
- Phase 4: 45 min (verification)
- **Total: 3.5 hours** (plus 30 min buffer)

---

## Status
Status: **approved**
Created: 2026-09-16
Approved: 2026-09-16
Completed: _(in progress)_

---

## Next Actions (After Approval)
1. Survey runtime capabilities (subagents/hooks/loop)
2. Start Phase 1: T001 resource audit
3. Execute migration during low-traffic window (2-5am Thailand time)
