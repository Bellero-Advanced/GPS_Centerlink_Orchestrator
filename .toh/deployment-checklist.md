# DLT Manual Override - Deployment Checklist

## ✅ Phase 1: Code & Migration (DONE)
- [x] Frontend components deployed
- [x] Database migrations synced
- [x] Edge Function deployed

## 🔧 Phase 2: Supabase Configuration (MANUAL REQUIRED)

### 1. Set Edge Function Secrets
Go to: https://supabase.com/dashboard/project/zenfuxlykduaxrsnhmlq/settings/functions

Add these secrets:
```bash
TRACCAR_API_URL=https://api.centerlink.co.th
TRACCAR_EMAIL=<admin@centerlink.co.th หรือ admin email ที่ใช้งานจริง>
TRACCAR_PASSWORD=<รหัสผ่าน admin>
WORKER_URL=https://api.centerlink.co.th
```

### 2. Enable pg_cron Extension
Go to: https://supabase.com/dashboard/project/zenfuxlykduaxrsnhmlq/database/extensions

Search for `pg_cron` and enable it.

### 3. Verify Cron Job
After enabling pg_cron, check if the cron job is active:
```sql
SELECT * FROM cron.job WHERE jobname = 'send-dlt-manual-batch';
```

Expected result:
- `schedule`: '*/60 * * * *' (every 60 seconds)
- `command`: calls `send-dlt-batch` Edge Function
- `active`: true

### 4. Test Manual Override
1. Go to: https://bellerox-gps.pages.dev/dlt-manual
2. Create a test override:
   - Select a vehicle
   - Click on map to set position
   - Choose status (moving/idle/stopped)
   - Set speed
   - Click "บันทึก"
3. Wait 60 seconds
4. Check "ประวัติการส่ง" tab for transmission log

## 📊 Monitoring

### Check Transmission Logs
```sql
SELECT * FROM dlt_transmission_log 
ORDER BY sent_at DESC 
LIMIT 10;
```

### Check Active Overrides
```sql
SELECT * FROM dlt_manual_overrides 
WHERE is_active = true;
```

### View Edge Function Logs
Go to: https://supabase.com/dashboard/project/zenfuxlykduaxrsnhmlq/logs/edge-functions

Filter by `send-dlt-batch` function.

## 🚨 Troubleshooting

### If cron job doesn't run:
1. Verify pg_cron is enabled
2. Check Edge Function secrets are set
3. View Edge Function logs for errors
4. Test function manually via Dashboard

### If DLT sending fails:
1. Check DLT credentials in Traccar user id=1 attributes
2. Verify WORKER_URL is correct
3. Check device has required DLT attributes (unit_id, etc.)
4. View transmission_log.error_message for details

## 📝 Next Steps After Configuration

1. Update team documentation
2. Train service team on manual override usage
3. Set up alerts for failed DLT transmissions
4. Monitor first 24h for any issues
