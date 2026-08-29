# Disaster Recovery Runbook
# Phase 14: Disaster Recovery
# Date: 2026-08-25

## Overview

This runbook provides step-by-step procedures for recovering the Bellerox GPS platform from various disaster scenarios.

**RTO (Recovery Time Objective):** 2 hours  
**RPO (Recovery Point Objective):** 24 hours (daily backups)

---

## Backup Schedule

**Automated Daily Backups:**
- **Time:** 2:00 AM UTC+7
- **Cron:** `0 2 * * * /opt/bellerox-gps/scripts/backup-database.sh`
- **Location:** `/opt/backups/postgres/`
- **Retention:** 7 daily, 4 weekly, 3 monthly

**What's Backed Up:**
- PostgreSQL database (full dump)
- Application code (Git repository)
- Configuration files (manual)

**What's NOT Backed Up:**
- Node modules (reinstallable)
- Build artifacts (reproducible)
- Logs (rotated automatically)

---

## Disaster Scenarios

### Scenario 1: Database Corruption

**Symptoms:**
- Database errors in logs
- Application crashes
- Data inconsistency

**Recovery Steps:**

1. **Stop the application:**
   ```bash
   pm2 stop bellerox-api
   ```

2. **Verify backup exists:**
   ```bash
   ls -lh /opt/backups/postgres/ | grep "$(date +%Y%m%d)"
   ```

3. **Restore from latest backup:**
   ```bash
   cd /opt/bellerox-gps/scripts
   ./restore-database.sh /opt/backups/postgres/latest.sql.gz
   ```

4. **Verify data integrity:**
   ```bash
   sudo -u postgres psql -d traccar -c "SELECT COUNT(*) FROM tc_devices;"
   ```

5. **Restart application:**
   ```bash
   pm2 restart bellerox-api
   curl http://localhost:3001/health
   ```

**Time:** ~15 minutes

---

### Scenario 2: Server Failure / VM Crash

**Symptoms:**
- Server unreachable
- SSH connection fails
- No response from services

**Recovery Steps:**

1. **Provision new VM** (GCP n2-standard-2, Ubuntu 22.04)

2. **Install dependencies:**
   ```bash
   # PostgreSQL
   sudo apt install postgresql-16

   # Node.js 20
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt install nodejs

   # PM2
   sudo npm install -g pm2

   # Docker (for monitoring)
   curl -fsSL https://get.docker.com | sh
   ```

3. **Restore from backups:**
   ```bash
   # Copy backups from GCS or offsite storage
   gsutil cp gs://bellerox-backups/latest.sql.gz /tmp/

   # Restore database
   sudo -u postgres createdb traccar
   gunzip -c /tmp/latest.sql.gz | sudo -u postgres psql -d traccar
   ```

4. **Deploy application:**
   ```bash
   git clone https://github.com/bellerox/gps-platform.git /opt/bellerox-gps
   cd /opt/bellerox-gps/bellerox-gps-web
   npm ci
   npm run build
   pm2 start server/index.js --name bellerox-api
   ```

5. **Update DNS** (if IP changed)

**Time:** ~1 hour

---

### Scenario 3: Accidental Data Deletion

**Symptoms:**
- User reports missing data
- Devices or positions deleted
- Audit log shows deletion event

**Recovery Steps:**

1. **Identify deletion time from audit log:**
   ```sql
   SELECT * FROM audit_log
   WHERE action LIKE '%delete%'
   ORDER BY created_at DESC
   LIMIT 10;
   ```

2. **Find backup before deletion:**
   ```bash
   ls -lt /opt/backups/postgres/ | head -20
   ```

3. **Restore to temporary database:**
   ```bash
   sudo -u postgres createdb traccar_restore
   gunzip -c /opt/backups/postgres/traccar_20260825_010000.sql.gz | \
     sudo -u postgres psql -d traccar_restore
   ```

4. **Extract deleted data:**
   ```sql
   # Connect to restore database
   sudo -u postgres psql -d traccar_restore

   # Copy deleted records to CSV
   \COPY (SELECT * FROM tc_devices WHERE id IN (123, 456)) TO '/tmp/deleted_devices.csv' CSV HEADER;
   ```

5. **Import to production:**
   ```sql
   # Connect to production
   sudo -u postgres psql -d traccar

   # Import records
   \COPY tc_devices FROM '/tmp/deleted_devices.csv' CSV HEADER;
   ```

6. **Verify and cleanup:**
   ```bash
   sudo -u postgres dropdb traccar_restore
   ```

**Time:** ~30 minutes

---

### Scenario 4: Code Deployment Failure

**Symptoms:**
- Application crashes after deployment
- Build errors
- Health check fails

**Recovery Steps:**

1. **Immediate rollback:**
   ```bash
   cd /opt/bellerox-gps/scripts
   ./rollback.sh
   ```

2. **Verify rollback:**
   ```bash
   curl http://localhost:3001/health
   pm2 logs bellerox-api --lines 50
   ```

3. **Investigate failure:**
   ```bash
   git log -5 --oneline
   git diff HEAD~1 HEAD
   ```

**Time:** ~5 minutes

---

## Point-in-Time Recovery (PITR)

PostgreSQL WAL (Write-Ahead Logging) allows recovery to any point in time.

**Enable WAL archiving:**

1. **Configure PostgreSQL:**
   ```bash
   # /etc/postgresql/16/main/postgresql.conf
   wal_level = replica
   archive_mode = on
   archive_command = 'test ! -f /opt/backups/wal/%f && cp %p /opt/backups/wal/%f'
   ```

2. **Create WAL directory:**
   ```bash
   mkdir -p /opt/backups/wal
   chown postgres:postgres /opt/backups/wal
   ```

3. **Restart PostgreSQL:**
   ```bash
   sudo systemctl restart postgresql
   ```

**Restore to specific time:**
```bash
# Stop application
pm2 stop bellerox-api

# Restore base backup
gunzip -c /opt/backups/postgres/base_backup.sql.gz | sudo -u postgres psql -d traccar

# Create recovery config
cat > /var/lib/postgresql/16/main/recovery.conf << EOF
restore_command = 'cp /opt/backups/wal/%f %p'
recovery_target_time = '2026-08-25 14:30:00'
EOF

# Start PostgreSQL (will replay WAL)
sudo systemctl start postgresql

# Restart application
pm2 restart bellerox-api
```

---

## Testing the DR Plan

**Quarterly DR Test (Every 3 months):**

1. **Test backup restore** (staging environment)
2. **Verify data integrity**
3. **Measure recovery time**
4. **Update runbook if needed**

**Test Checklist:**
- [ ] Backup script runs successfully
- [ ] Restore completes without errors
- [ ] Application starts and passes health check
- [ ] Data integrity verified
- [ ] Recovery time documented

---

## Contacts

**On-Call Engineer:** [Phone number]  
**Database Admin:** [Phone number]  
**DevOps Lead:** [Phone number]

**Escalation:**
1. On-Call Engineer (0-15 min)
2. Team Lead (15-30 min)
3. CTO (30+ min)

---

## Monitoring & Alerts

**Critical Alerts:**
- Database down
- Disk usage > 90%
- Backup failed
- API health check failed

**Alert Channels:**
- Slack: #ops-alerts
- Email: ops@bellerox.com
- SMS: Critical only

---

## Post-Incident

**After recovery:**
1. Document incident timeline
2. Perform root cause analysis
3. Update runbook if needed
4. Review monitoring/alerts
5. Schedule postmortem meeting

**Incident Report Template:**
```markdown
# Incident Report

**Date:** [Date]
**Duration:** [Duration]
**Impact:** [Impact description]
**Root Cause:** [Root cause]
**Resolution:** [What fixed it]
**Action Items:** [Preventive measures]
```

---

## Version History

- **v1.0** (2026-08-25): Initial DR runbook
