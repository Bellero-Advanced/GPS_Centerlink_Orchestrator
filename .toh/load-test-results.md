# Load Test Results — GPS Server Architecture (20k+ Vehicles)

**Test Date:** Pending deployment  
**Goal:** Validate system handles 20,000 concurrent GPS devices + 10 concurrent users

---

## Test Plan

### Test 1: GPS Device Load (20,000 concurrent)
```bash
cd /opt/bellerox-gps
node scripts/load-test-gps-devices.js --devices=20000 --interval=30
```

**Expected Results:**
- All 20,000 devices connect successfully (< 5 min connection time)
- Position write rate: 667/sec sustained (20,000 devices ÷ 30 sec)
- HAProxy distributes load evenly across 3 Traccar instances
- PostgreSQL handles 667 TPS without lag
- CPU usage < 80% across all instances
- Memory usage < 12 GB per VM

**Metrics to Capture:**
- Connection success rate (target: > 99%)
- Position lag: GPS → PostgreSQL (target: < 5 seconds)
- HAProxy session distribution (should be ~6,666 per backend)
- PostgreSQL TPS (via Prometheus)
- CPU/Memory (via Grafana dashboard)

---

### Test 2: WebSocket Concurrent Users (10 users)
```bash
TRACCAR_URL=https://traccar.gps.bellerox.com \
TRACCAR_EMAIL=admin@bellerox.com \
TRACCAR_PASSWORD=<password> \
node scripts/load-test-websocket-users.js
```

**Expected Results:**
- All 10 users connect successfully
- Each user receives position updates in real-time (< 1 sec lag)
- No WebSocket disconnections during 5-min test
- Position broadcast rate: ~667 messages/sec × 10 users = 6,670 broadcasts/sec

**Metrics to Capture:**
- Messages received per user (should be similar across all users)
- Average position lag (target: < 1 second)
- WebSocket error rate (target: 0%)

---

### Test 3: Combined Load (Full Stress)
Run both tests simultaneously:
- Terminal 1: GPS device simulator (20,000 devices)
- Terminal 2: WebSocket users (10 concurrent)
- Terminal 3: Grafana monitoring

**Duration:** 1 hour continuous

**Success Criteria:**
- System remains stable for entire duration
- No crashes or OOM errors
- Position lag < 5 seconds
- API response time (p95) < 1 second
- No PostgreSQL connection pool exhaustion
- No HAProxy backend failures

---

## Deployment Checklist (Before Running Tests)

### 1. Infrastructure Deployed
- [ ] 3× GCP e2-standard-4 VMs (4 vCPU / 16 GB RAM each)
- [ ] PostgreSQL config: `postgresql.conf` applied (8GB shared_buffers)
- [ ] TimescaleDB hypertable created: `init-timescale.sql` executed
- [ ] Indexes created: `indexes.sql` executed
- [ ] HAProxy running with 19 GPS protocol frontends
- [ ] 3 Traccar instances behind HAProxy
- [ ] Redis cluster (master + 2 replicas)
- [ ] Monitoring stack (Prometheus + Grafana)

### 2. System Configuration
- [ ] File descriptors: `ulimit -n` = 65535
- [ ] Kernel tuning applied: `sysctl -p` (somaxconn=65535)
- [ ] Swap enabled: 8 GB
- [ ] Firewall rules: GPS ports 5001-5093 open

### 3. Docker Containers Running
```bash
# On each VM:
cd /opt/bellerox-gps/infrastructure/docker
docker-compose -f docker-compose.scale.yml up -d

# Check status:
docker-compose -f docker-compose.scale.yml ps
```

Expected containers:
- haproxy (1 instance)
- postgres (1 instance)
- pgbouncer (1 instance)
- redis-master, redis-replica1, redis-replica2 (3 instances)
- traccar1, traccar2, traccar3 (3 instances)
- nginx (1 instance)

### 4. Monitoring Setup
```bash
cd /opt/bellerox-gps/infrastructure/monitoring
docker-compose -f docker-compose.monitoring.yml up -d
```

Access Grafana: `http://<vm-ip>:3000`
- Dashboard: "Bellerox GPS - Performance Dashboard"
- Watch: Position write rate, DB connections, HAProxy sessions, CPU/memory

---

## Post-Test Analysis

### Metrics to Review in Grafana

**1. Position Write Rate**
- Query: `rate(pg_stat_database_xact_commit{datname="traccar"}[1m])`
- Expected: ~667 TPS sustained
- Threshold: Must not drop below 500 TPS

**2. PostgreSQL Connection Pool**
- Query: `sum(pg_stat_activity_count)`
- Expected: 60-80 active connections (out of 200 max)
- Alert if: > 180 (pool near exhaustion)

**3. HAProxy Active Sessions**
- Query: `haproxy_frontend_current_sessions`
- Expected: ~20,000 total across all frontends
- Distribution: ~6,666 per backend (traccar1/2/3)

**4. System Resources**
- CPU: `100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- Memory: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
- Expected: CPU < 80%, Memory < 80%

**5. Redis Operations**
- Query: `redis_instantaneous_ops_per_sec`
- Expected: > 1,000 ops/sec (once Redis plugin deployed)

---

## Known Limitations (Before Full Deployment)

### Redis Plugin Not Yet Implemented
- **Impact:** No Redis caching or pub/sub for this test
- **Workaround:** Use HAProxy sticky sessions for WebSocket
- **Next Step:** Build Redis plugin in Phase 2

### TimescaleDB First-Time Conversion
- **Impact:** Initial hypertable conversion takes ~5 minutes for existing data
- **Action:** Run `init-timescale.sql` during maintenance window

### Load Test Scripts Require Node.js
```bash
# Install Node.js on test machine (not production VM)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install WebSocket library
npm install ws
```

---

## Expected Performance Summary

| Metric | Current (Single) | Target (Multi-Instance) | Achieved |
|--------|------------------|-------------------------|----------|
| Max Concurrent Devices | 4,000 | 20,000+ | Pending |
| Position Write Rate | 133 TPS | 667 TPS | Pending |
| Position Lag | < 2 sec | < 5 sec | Pending |
| API Response (p95) | < 500 ms | < 1 sec | Pending |
| WebSocket Users | 5 | 10+ | Pending |
| System Uptime | 99% | 99.9% | Pending |

---

## Next Steps After Load Test

**If PASS (all metrics within target):**
1. Document actual performance numbers in this file
2. Deploy to production GCP VMs
3. Update `.claude/rules/infrastructure.md` with scale architecture
4. Monitor real-world load for 1 week

**If FAIL (metrics below target):**
1. Identify bottleneck from Grafana metrics
2. Tune configuration (increase heap, connection pool, etc.)
3. Re-run load test
4. Escalate if hardware insufficient (scale to e2-standard-8)

---

## Production Deployment Notes

**Cost Estimate (3× e2-standard-4 VMs in GCP asia-southeast1):**
- Compute: 3 × $130/month = $390/month
- Cloud SQL (optional upgrade): +$200/month
- Memorystore Redis (optional): +$50/month
- **Total:** ~$640/month for 20k+ vehicle capacity

**Revenue at 20k vehicles × ฿35/vehicle:**
- ฿700,000/month (~$20,000/month)
- Infrastructure cost: 3.2% of revenue ✅

---

**Status:** Ready for deployment and load testing

**Test Runner:** Pending execution after infrastructure deployed
