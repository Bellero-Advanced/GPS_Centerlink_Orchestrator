# Infrastructure & Deployment — Bellerox GPS
# Scale: 4,000 → 20,000+ vehicles · Region: GCP asia-southeast1 (Singapore)

## Cloud Architecture

### GCP Services Used

| Service | Purpose | Config |
|---------|---------|--------|
| Compute Engine | Traccar Java server | 3× e2-standard-4 (4 vCPU / 16 GB RAM each) |
| Cloud SQL | PostgreSQL 16 | db-n1-standard-4, 100GB SSD, automated backup |
| Memorystore Redis | Live position cache + pub/sub | 512MB master + 2 replicas |
| Cloud Load Balancing | TCP load balancer for GPS device ports | HAProxy (self-hosted) |
| Cloud CDN | Static asset caching | Cloudflare handles this |
| Cloud Storage | PostgreSQL backups, vehicle photos | Standard class |
| Cloud Armor | DDoS protection | Basic |

### Multi-Instance Architecture (20k+ Vehicles)

```
GPS Devices (20,000+)
    ↓
HAProxy TCP Load Balancer (port 5001-5093)
    ├─→ Traccar Instance 1 (8082) ─┐
    ├─→ Traccar Instance 2 (8083) ─┼─→ PgBouncer → PostgreSQL
    └─→ Traccar Instance 3 (8084) ─┘        ↓
                                      Redis Cluster (master + 2 replicas)
                                            ↓
                                      Nginx (SSL termination)
                                            ↓
                                      Cloudflare Worker
                                            ↓
                                      Web App (React)
```

**Key Design Decisions:**
- **HAProxy for device connections:** Sticky sessions by source IP (device keeps same backend)
- **Nginx for API:** Round-robin across 3 Traccar instances
- **Redis:** Cache layer (strategy documented, plugin optional)
- **PgBouncer:** Transaction pooling (300 client connections → 100 PostgreSQL connections)

### DNS / CDN via Cloudflare

| Hostname | Proxy | Target |
|----------|-------|--------|
| `gps.bellerox.com` | CF Pages | Bellerox GPS Web App |
| `api.gps.bellerox.com` | CF Worker | Traccar API proxy |
| `traccar.gps.bellerox.com` | DNS only (gray) | GCP VM public IP |

**Why gray-cloud for traccar.gps.bellerox.com?**
GPS devices connect directly to the server via TCP (not HTTP). Cloudflare proxy doesn't work for TCP.
Only the HTTPS API (port 443 via Nginx) benefits from Cloudflare.

### Firewall Rules (GCP VPC)

```
# GPS device protocols — open to world
tcp:5001-5093  # All Traccar protocols (Thai market: 5001,5002,5004,5007,5009,5013,5020,5022,5023,5027,5039,5044,5046,5055,5078,5082,5093,5143,5222)

# HTTPS (Nginx → Traccar API) — Cloudflare IPs only
tcp:443 — source: Cloudflare IP ranges

# HTTP (Let's Encrypt) — open
tcp:80

# HAProxy stats page
tcp:8404

# SSH — whitelisted IPs only
tcp:22

# Internal only (NOT exposed)
tcp:8082,8083,8084  # Traccar API instances
tcp:5432            # PostgreSQL
tcp:6379            # Redis
```

## Docker Compose Services

### Scaling Traccar to 20k+ Vehicles

**File:** `infrastructure/docker/docker-compose.scale.yml`

**Architecture:**
- 3 Traccar instances (traccar1, traccar2, traccar3)
- HAProxy distributes GPS device connections (sticky by source IP)
- Nginx load balances HTTP API requests (round-robin)
- Redis cluster (master + 2 replicas) for caching
- PgBouncer connection pooler

**Resource Allocation per VM (16 GB RAM):**
```
PostgreSQL:     8 GB  (shared_buffers 8GB)
Traccar JVM:    10 GB (heap -Xmx8g + native overhead)
Redis:          600 MB
HAProxy:        256 MB
Nginx:          256 MB
PgBouncer:      128 MB
System:         ~800 MB
```

### HAProxy Configuration

**File:** `infrastructure/haproxy/haproxy.cfg`

**Key Features:**
- 19 GPS protocol frontends (GT06, Teltonika, OsmAnd, etc.)
- Balance algorithm: `source` with `hash-type consistent`
- Health checks every 10 seconds
- Stats page: `http://localhost:8404/stats`

**Example backend:**
```haproxy
backend traccar_gt06
    balance source
    hash-type consistent
    server traccar1 traccar1:5023 check inter 10s fall 3 rise 2
    server traccar2 traccar2:5023 check inter 10s fall 3 rise 2
    server traccar3 traccar3:5023 check inter 10s fall 3 rise 2
```

### PostgreSQL Tuning (for 20k+ vehicles)

**File:** `infrastructure/postgres/postgresql.conf`

**High-Write Optimizations:**
```
shared_buffers = 8GB              # 50% of RAM
effective_cache_size = 12GB       # 75% of RAM
max_connections = 200
work_mem = 32MB
maintenance_work_mem = 1GB
wal_level = minimal               # No replication = faster writes
synchronous_commit = off          # Safe for GPS data (lose < 1 position in crash)
wal_buffers = 64MB                # Larger WAL buffer
max_wal_size = 8GB                # Allow WAL growth before checkpoint
checkpoint_timeout = 15min        # Less frequent checkpoints
checkpoint_completion_target = 0.9
random_page_cost = 1.1            # SSD
effective_io_concurrency = 200    # SSD parallel I/O
autovacuum_vacuum_scale_factor = 0.05  # Vacuum when 5% updated (was 20%)
```

**Expected Performance:**
- Sustain 667 position writes/sec (20,000 devices ÷ 30 sec interval)
- Query response < 100ms for position lookups
- Connection pool utilization < 80%

### TimescaleDB for Time-Series Positions

**File:** `infrastructure/postgres/init-timescale.sql`

**Benefits:**
- Automatic partitioning by time (1-day chunks)
- 10-20× compression for historical data (> 7 days old)
- Fast queries on time ranges
- Automatic retention policy (drop chunks > 90 days)

**Conversion:**
```sql
SELECT create_hypertable('tc_positions', 'servertime', chunk_time_interval => INTERVAL '1 day');
SELECT add_compression_policy('tc_positions', INTERVAL '7 days');
SELECT add_retention_policy('tc_positions', INTERVAL '90 days');
```

### Critical PostgreSQL Indexes

**File:** `infrastructure/postgres/indexes.sql`

Run after Traccar creates schema (first startup):

```sql
-- Live position lookup (map display)
CREATE INDEX CONCURRENTLY idx_tc_positions_device_fixtime
  ON tc_positions (deviceid, fixtime DESC);

-- Position history (trip reports)
CREATE INDEX CONCURRENTLY idx_tc_positions_device_fixtime_range
  ON tc_positions (deviceid, fixtime) WHERE valid = TRUE;

-- Cleanup (retention policy)
CREATE INDEX CONCURRENTLY idx_tc_positions_servertime
  ON tc_positions (servertime);

-- Events by device + time
CREATE INDEX CONCURRENTLY idx_tc_events_device_time
  ON tc_events (deviceid, eventtime DESC);
```

### Redis Cluster (Cache + Pub/Sub)

**File:** `infrastructure/docker/docker-compose.scale.yml`

**Architecture:**
- 1 master (read/write)
- 2 replicas (read-only, automatic failover)
- 512 MB per instance (1.5 GB total)

**Use Cases:**
- **Position cache:** Latest position per device (< 10ms read)
- **Pub/Sub:** Broadcast position updates to all Traccar instances (WebSocket coordination)

**Implementation Status:**
- ✅ Redis cluster deployed
- 📋 Position cache: Strategy documented, requires Traccar plugin (optional)
- 📋 Pub/Sub: Strategy documented, requires Traccar plugin (optional)
- 🎯 **Recommendation:** Start with Nginx cache + HAProxy sticky sessions (no code changes)

### Connection Pool Configuration

**Traccar (traccar.xml):**
```xml
<entry key='database.maxPoolSize'>100</entry>
<entry key='database.connectionTimeout'>30000</entry>
<entry key='server.timeout'>300</entry>  <!-- 5 min idle → disconnect -->
```

**PgBouncer:**
```
MAX_CLIENT_CONN = 300       # Traccar clients
DEFAULT_POOL_SIZE = 100     # PostgreSQL connections
MIN_POOL_SIZE = 20
RESERVE_POOL_SIZE = 20
POOL_MODE = transaction     # Best for JDBC
```

**Connection Flow:**
```
3 Traccar instances × 100 connections = 300 client connections
    ↓
PgBouncer (transaction pooling)
    ↓
100 connections → PostgreSQL (max 200)
```

## System Configuration

### File Descriptor Limits (CRITICAL)

**File:** `infrastructure/scripts/setup-server.sh`

```bash
# Increase to 65535 (default 1024 will crash at ~1000 devices)
ulimit -n 65535

# Persistent across reboots
cat >> /etc/security/limits.conf <<EOF
* soft nofile 65535
* hard nofile 65535
EOF
```

### Kernel Network Tuning

**File:** `infrastructure/scripts/setup-server.sh`

```bash
# TCP connection handling for 20k+ devices
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_congestion_control = bbr
```

## Monitoring & Alerting

### Prometheus + Grafana Stack

**File:** `infrastructure/monitoring/docker-compose.monitoring.yml`

**Services:**
- Prometheus (metrics collection, 30-day retention)
- Grafana (visualization dashboards)
- Node Exporter (system metrics: CPU, memory, disk)
- PostgreSQL Exporter (DB metrics)
- Redis Exporter (cache metrics)
- HAProxy Exporter (load balancer metrics)

**Access:**
- Grafana: `http://localhost:3000` (admin / ${GRAFANA_PASSWORD})
- Prometheus: `http://localhost:9090`
- HAProxy Stats: `http://localhost:8404/stats`

### Key Metrics Dashboard

**File:** `infrastructure/monitoring/grafana/dashboards/traccar-performance.json`

**Panels:**
1. GPS Position Write Rate (target: 667/sec)
2. PostgreSQL Active Connections (threshold: 180/200)
3. HAProxy Active Device Connections (per backend distribution)
4. System Resources (CPU & Memory %)
5. Redis Operations Rate
6. Traccar Instance Health (3/3 up)

### Alert Rules

**File:** `infrastructure/monitoring/prometheus/alerts.yml`

**Critical Alerts:**
- PostgreSQL down (> 1 min)
- HAProxy backend down (> 1 min)
- Redis down (> 1 min)
- No GPS positions received (> 10 min)

**Warning Alerts:**
- High CPU usage (> 90% for 5 min)
- High memory usage (> 90% for 5 min)
- PostgreSQL connection pool high (> 180/200)
- Position lag high (> 300 sec)

## Load Testing

### GPS Device Simulator

**File:** `scripts/load-test-gps-devices.js`

```bash
node scripts/load-test-gps-devices.js --devices=20000 --interval=30
```

Simulates 20,000 GT06 GPS trackers sending positions every 30 seconds.

**Expected Results:**
- Connection success rate: > 99%
- Position write rate: 667/sec sustained
- Position lag: < 5 seconds

### WebSocket Stress Test

**File:** `scripts/load-test-websocket-users.js`

```bash
TRACCAR_URL=https://traccar.gps.bellerox.com \
TRACCAR_EMAIL=admin@bellerox.com \
TRACCAR_PASSWORD=<password> \
node scripts/load-test-websocket-users.js
```

Simulates 10 concurrent users viewing live map for 5 minutes.

**Expected Results:**
- All users connected successfully
- Position updates received in < 1 second
- No WebSocket disconnections

### Load Test Results

**File:** `.toh/load-test-results.md`

Status: Ready for execution (pending infrastructure deployment)

## Deployment

### First-Time Setup

```bash
# 1. Run setup script on GCP VM
bash infrastructure/scripts/setup-server.sh

# 2. Copy infrastructure files
scp -r infrastructure/ user@vm:/opt/bellerox-gps/

# 3. Create .env file
cd /opt/bellerox-gps/infrastructure/docker
cat > .env <<EOF
POSTGRES_PASSWORD=<secure-password>
REDIS_PASSWORD=<secure-password>
GRAFANA_PASSWORD=<secure-password>
EOF

# 4. Start multi-instance stack
docker-compose -f docker-compose.scale.yml up -d

# 5. Wait for Traccar to create schema (2-3 min)
docker-compose -f docker-compose.scale.yml logs -f traccar1

# 6. Run TimescaleDB conversion
docker exec -it bellerox-postgres psql -U traccar -d traccar -f /docker-entrypoint-initdb.d/init-timescale.sql

# 7. Create indexes
docker exec -it bellerox-postgres psql -U traccar -d traccar -f /docker-entrypoint-initdb.d/indexes.sql

# 8. Start monitoring stack
cd ../monitoring
docker-compose -f docker-compose.monitoring.yml up -d

# 9. Verify all services
docker ps  # Should see 13 containers running
```

### Health Check

```bash
# HAProxy stats
curl http://localhost:8404/stats

# Traccar instances
curl http://localhost:8082/api/server  # traccar1
curl http://localhost:8083/api/server  # traccar2
curl http://localhost:8084/api/server  # traccar3

# PostgreSQL
docker exec bellerox-postgres pg_isready -U traccar

# Redis
docker exec bellerox-redis-master redis-cli --pass <password> ping

# Grafana
curl http://localhost:3000/api/health
```

## Cost Estimates

### Phase 1 (Current: 4,000 vehicles)
| Resource | Config | Monthly Cost |
|----------|--------|-------------|
| GCE VM | e2-standard-2 | ~$100 |
| Cloud SQL | db-n1-standard-2 | ~$100 |
| Redis | Basic 1GB | ~$25 |
| Cloud Storage | 1TB backup | ~$23 |
| Egress | 500GB | ~$50 |
| **Total** | | **~$300/month** |

Revenue: 4,000 vehicles × ฿35 = ฿140,000/month (~$4,000)
Infrastructure: 7.5% of revenue ✅

### Phase 2 (Target: 20,000 vehicles)
| Resource | Config | Monthly Cost |
|----------|--------|-------------|
| GCE VM | 3× e2-standard-4 | ~$390 |
| Cloud SQL | db-n1-standard-4 | ~$200 |
| Redis | 512MB × 3 | ~$75 |
| Cloud Storage | 3TB backup | ~$69 |
| Egress | 2TB | ~$200 |
| **Total** | | **~$934/month** |

Revenue: 20,000 vehicles × ฿35 = ฿700,000/month (~$20,000)
Infrastructure: 4.7% of revenue ✅

### Phase 3 (Scale: 100,000 vehicles)
| Resource | Config | Monthly Cost |
|----------|--------|-------------|
| GKE Cluster | 5× n2-standard-8 nodes | ~$2,500 |
| Cloud SQL Enterprise | db-n1-standard-16 | ~$1,200 |
| Memorystore Redis | 10GB cluster | ~$300 |
| Cloud Storage | 15TB | ~$345 |
| Egress | 10TB | ~$1,000 |
| **Total** | | **~$5,345/month** |

Revenue: 100,000 vehicles × ฿32 avg = ฿3,200,000/month (~$91,000)
Infrastructure: 5.9% of revenue ✅

## Backup Strategy

**PostgreSQL:**
- Automated daily backup (Cloud SQL native or pg_dump → GCS)
- 7 days local retention, 90 days GCS retention
- RPO: 24 hours, RTO: 2 hours

**Redis:**
- No persistence (cache layer only)
- Master failover to replica (< 1 min)

**Traccar Config:**
- Git repository (infrastructure/ folder)
- Encrypted secrets (GCP Secret Manager)

## Security

- File descriptors: 65535 (prevents crash under load)
- Firewall: GPS ports open, admin ports restricted
- SSL: Let's Encrypt via Certbot
- Database: PgBouncer pooling, no direct exposure
- Secrets: Environment variables, never in git

## Known Limitations

1. **Redis Plugin:** Not yet implemented (optional feature)
   - Current: Nginx cache + HAProxy sticky sessions (works today)
   - Future: Custom Traccar plugin for Redis cache + pub/sub

2. **JMX Metrics:** Traccar JMX exporter not configured
   - Current: Monitor via PostgreSQL metrics + HAProxy stats
   - Future: Add JMX Java agent to Traccar containers

3. **Multi-Region:** Single region (asia-southeast1)
   - Latency from Australia: ~100-150ms
   - Future: Add sydney region for ANZ customers

## Troubleshooting

**Problem:** Devices not connecting
- Check: `docker logs bellerox-haproxy` for connection attempts
- Check: Firewall rules (GPS ports 5001-5093 open?)
- Check: HAProxy stats page (backends up?)

**Problem:** Position lag > 5 seconds
- Check: PostgreSQL TPS in Grafana (should be ~667/sec)
- Check: CPU usage (should be < 80%)
- Check: `docker exec bellerox-postgres psql -U traccar -c "SELECT COUNT(*) FROM pg_stat_activity"`

**Problem:** "Too many open files" error
- Check: `ulimit -n` (should be 65535, not 1024)
- Fix: Run setup-server.sh again, restart Docker

**Problem:** PostgreSQL connection pool exhausted
- Check: `pg_stat_activity` count (should be < 180)
- Fix: Increase `database.maxPoolSize` in traccar.xml
- Restart: `docker-compose restart traccar1 traccar2 traccar3`
