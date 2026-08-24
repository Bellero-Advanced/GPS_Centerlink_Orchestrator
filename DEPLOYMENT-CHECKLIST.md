# ✅ Deployment Checklist - 2026-08-24

**Status**: 🟡 Partial Complete  
**Rollback**: ✅ Complete  
**Plan Merge**: ✅ Complete  
**Deploy**: ⚠️ Pending

---

## ✅ งานที่เสร็จแล้ว

### 1. Source Code
- ✅ Rollback `bellerox-gps-web` → commit `263f694`
- ✅ Force push to GitHub
- ✅ Build success (dist/ ready)
- ✅ Root repository committed

### 2. Production Services
- ✅ Restart `centerlink-traccar`
- ✅ Restart `centerlink-nginx`
- ✅ Restart `centerlink-postgres`
- ✅ All services healthy

### 3. Documentation
- ✅ Merge `plan_2.md` → `plan.md`
- ✅ Phase 7, 9-10 documented as complete
- ✅ Rollback documentation created
- ✅ All commits pushed

---

## ⚠️ งานที่ค้าง (Deploy)

### Frontend Deployment
**Status**: ⚠️ Build แล้วแต่ยังไม่ได้ deploy

**สาเหตุ**: Node v20 ไม่รองรับ wrangler latest (ต้องการ v22+)

**ตัวเลือก:**

#### Option A: GitHub Actions (แนะนำ)
```bash
cd bellerox-gps-web
git add .
git commit -m "trigger deploy"
git push origin main
# GitHub Actions CI จะ deploy อัตโนมัติ
```

**ข้อดี:**
- ✅ ใช้ Node 22+ บน GitHub runner
- ✅ Deploy อัตโนมัติ
- ✅ Build logs มองเห็นได้
- ✅ ไม่ต้อง upgrade Node ใน local

#### Option B: Manual Deploy บน Production Server
```bash
# SSH เข้า bellerox-gps-vm
gcloud compute ssh bellerox-gps-vm \
  --zone=asia-southeast1-a \
  --project=gen-lang-client-0664890248 \
  --tunnel-through-iap

# Clone repo (ถ้ายังไม่มี)
cd /opt
sudo git clone https://github.com/Bellero-Advanced/GPS_Centerlink_Orchestrator.git frontend
cd frontend/bellerox-gps-web

# Build และ deploy
npm install
npm run build
npx wrangler@latest pages deploy dist --project-name=gpsthailand-centerlink
```

**ข้อดี:**
- ✅ Deploy ได้ทันที
- ✅ Production server มี Node 22+

**ข้อเสีย:**
- ⚠️ ต้อง SSH manual
- ⚠️ ต้อง setup Wrangler auth บน server

---

## 🧪 Verification Steps (หลัง Deploy)

### 1. เช็ค Frontend
```bash
curl -I https://gps.bellerox.com
# HTTP/2 200 OK
```

### 2. ทดสอบ Login
```
URL: https://gps.bellerox.com
Username: admin_gpsthailand
Password: (ใช้ password ที่ตั้งไว้)
```

**Expected:**
- ✅ Login form แสดง
- ✅ Submit → redirect to `/live-map`
- ✅ Dashboard แสดงรถทั้งหมด

### 3. เช็ค WebSocket
**Browser Console:**
```javascript
// ควรเห็น:
[GPS WebSocket] Connected ✅
[GPS WebSocket] Applying brand colors: {...}
```

**ถ้าเห็น error:**
```
WebSocket connection to 'wss://traccar.gps.bellerox.com/socket.io/' failed
```
→ ปัญหา CORS หรือ nginx config

### 4. เช็ค API
```bash
# Health check
curl https://api.gps.bellerox.com/api/server
# {"version":"6.14.5",...}

# Activity endpoint (ต้อง auth)
curl https://api.gps.bellerox.com/api/reports/activity?deviceId=1&date=2026-08-24 \
  -H "Cookie: JSESSIONID=xxx"
```

---

## 📊 Current Status

**Backend (Production):**
- ✅ Traccar: Running (just restarted)
- ✅ Nginx: Running (just restarted)
- ✅ PostgreSQL: Running (just restarted)
- ✅ Database: 37 users, 4 admins, 189 vehicles

**Frontend:**
- ✅ Source: commit 263f694
- ✅ Build: Success (dist/ exists)
- ⚠️ Deploy: **NOT DEPLOYED YET**
- ❌ Login test: Pending (รอ deploy)

**Documentation:**
- ✅ plan.md: Merged Phase 7, 9-10
- ✅ Rollback: Documented
- ✅ All commits: Pushed to GitHub

---

## 🎯 Recommendation

**แนะนำ Option A (GitHub Actions)** เพราะ:
1. ไม่ต้อง upgrade Node local
2. Deploy automated ทุกครั้งที่ push
3. Build logs trackable
4. No manual SSH required

**คำสั่งเดียวจบ:**
```bash
cd bellerox-gps-web
git push origin main
# GitHub Actions จะทำส่วนที่เหลือให้
```

---

## ⏭️ Next Actions

1. **Deploy frontend** (เลือก Option A หรือ B)
2. **Test login** ด้วย admin_gpsthailand
3. **Verify WebSocket** ใน browser console
4. **Smoke test** ทุกหน้าหลัก (live-map, fleet, reports)

---

**สรุป:**
- ✅ Rollback done
- ✅ Plans merged  
- ✅ Services restarted
- ⚠️ **Frontend deploy pending** ← ขั้นตอนสุดท้าย
