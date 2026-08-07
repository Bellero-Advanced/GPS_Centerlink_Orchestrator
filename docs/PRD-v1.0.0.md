# Bellerox GPS — Product Requirements Document
# Version 1.0.0 — Launch Ready
# สถานะ: Draft · วันที่: 2026-06-30

---

## Executive Summary

**Bellerox GPS** คือ GPS Fleet Management SaaS สำหรับธุรกิจขนส่งไทย  
**v1.0.0** คือ release แรกที่พร้อมขายได้จริง ครอบคลุมยานพาหนะสูงสุด 5,000 คัน  
Target launch: **ภายใน 60 วันหลัง PRD นี้ได้รับอนุมัติ**

---

## 1. Product Vision

> "แดชบอร์ด GPS ที่ fleet manager ไทยต้องการ — ดูแล้วเข้าใจทันที ใช้ได้บนมือถือ ราคาสมเหตุสมผล"

**Problems we solve:**
- คู่แข่งในไทย (iFleet, Thai GPS Tracker) มี UI เก่า ไม่รองรับมือถือ
- Geotab / CarTrack ราคาแพง UI เป็นภาษาอังกฤษล้วน
- ขาดการแจ้งเตือน Real-time ผ่าน LINE (ที่ธุรกิจไทยใช้)

**Differentiators:**
- Thai-first UX (Sarabun font, Thai address, LINE Notify)
- Modern design (Notion-inspired, Dime-style mobile)
- Open protocol (Traccar: 200+ GPS devices)
- ราคา ฿300-500/vehicle/month (ต่ำกว่าคู่แข่ง 40%)

---

## 2. Target Users (v1.0.0)

| Persona | คำอธิบาย | Pain Point |
|---------|---------|-----------|
| **Fleet Manager** | ดูแลรถ 10-200 คัน ใน logistics SME | ต้องเปิดหน้าจอทั้งวัน ไม่มีแจ้งเตือนอัตโนมัติ |
| **Business Owner** | เจ้าของธุรกิจขนส่ง หรือ บริษัทรับเหมา | ต้องการ dashboard overview รวดเร็ว |
| **Driver / Field Staff** | พนักงานส่งของ / คนขับ | ต้องการ track ตัวเองผ่าน app มือถือ |

---

## 3. Scope — Version 1.0.0

### ✅ IN SCOPE (Must have for launch)

#### 3.1 Web App (gps.bellerox.com)
| Feature | Description | Status |
|---------|-------------|--------|
| Login / Session | Email+password, auto-logout 401 | ✅ Done |
| Dashboard | KPI cards (total/online/moving/offline) + vehicle list | ✅ Done |
| Live Map | Leaflet + OpenStreetMap + vehicle markers + status filter + click-to-focus | ✅ Done |
| Fleet Management | Vehicle list, add, delete, IMEI/status display | ✅ Done |
| Reports — Trips | Trip list per vehicle, date picker, distance/duration/speed | ✅ Done |
| Reports — Summary | Per-vehicle daily summary, CSV export | ✅ Done |
| Alerts | Recent 24h events list, severity badges, event type Thai labels | ✅ Done |
| Geofences | List geofences, delete, view area type | ✅ Done |
| Settings — Appearance | Dark/Light/System mode toggle | ✅ Done |
| Settings — LINE Notify | Token input + save + instructions | ✅ Done |
| Settings — Alert Rules | Toggle rules (overspeed, geofence, offline, idle, towing) | ✅ Done |
| Responsive | Works on 375px mobile width | ✅ Done |
| Thai text | Sarabun font, Thai labels throughout | ✅ Done |

#### 3.2 Mobile App (iOS + Android via Expo)
| Feature | Description | Status |
|---------|-------------|--------|
| Login | Email/password, dark Dime theme | ✅ Done |
| Live Map | react-native-maps + vehicle markers | ✅ Done |
| Fleet List | Vehicle cards (status dot, speed, address) + search | ✅ Done |
| Alerts | Mock alerts (real-time in v1.1) | ✅ Done |
| Profile | User info, system info, logout | ✅ Done |
| Dark theme | #09090F background, Dime-inspired | ✅ Done |

#### 3.3 Infrastructure
| Component | Description | Status |
|-----------|-------------|--------|
| Traccar Server | Docker, GCP asia-southeast1 | ✅ Ready (needs GCP VM) |
| PostgreSQL 16 | TimescaleDB-ready, tuned for 100k vehicles | ✅ Done |
| Redis | Live position cache | ✅ Done |
| Nginx | SSL, WebSocket proxy | ✅ Done |
| Cloudflare Worker | CORS proxy api.gps.bellerox.com | ✅ Live |
| Cloudflare Pages | Web app gps.bellerox.com | ✅ Live (pending custom domain) |
| Let's Encrypt SSL | Auto-renew cert | ✅ Ready |
| GCP Terraform | VM + Cloud SQL + Redis + Firewall | ✅ Ready |
| Backup scripts | PostgreSQL → GCS daily | ✅ Done |

### ❌ OUT OF SCOPE (v1.1+)
- Geofence drawing on map (UI draw tool)
- Trip replay animation
- Driver behavior scoring
- Real-time alerts on mobile (push notification)
- Multi-language (APAC)
- White-label
- ERP integration (JINKIN ERP)
- OBD-II data

---

## 4. Technical Requirements

### 4.1 Performance
| Metric | Target | How |
|--------|--------|-----|
| Map load time | < 2s on 4G | Leaflet lazy load, code split |
| Position update latency | < 1s | WebSocket (Traccar native) |
| Dashboard load | < 1s (cached) | React Query 30s stale |
| API response | < 200ms p95 | GCP asia-southeast1 proximity |
| Mobile app start | < 3s cold start | Expo SDK 51 + metro bundler |

### 4.2 Scale (v1.0.0 target)
| Parameter | Target |
|-----------|--------|
| Max vehicles | 5,000 |
| Concurrent users | 200 |
| Position updates/sec | 500 (1 per 10s per vehicle) |
| Data retention | 90 days positions |
| Server | GCP e2-standard-4 (4 vCPU, 16GB RAM) |

### 4.3 Security
- Basic auth credentials via Axios interceptor only (never in URL)
- Cloudflare Worker hides Traccar server address
- Traccar port 8082 NOT exposed to internet
- HTTPS everywhere (Let's Encrypt)
- Thai PDPA compliant: driver location = personal data, consent required
- No GPS positions logged to console in production

### 4.4 Compatibility
| Platform | Minimum |
|----------|---------|
| Web | Chrome 90+, Safari 15+, Firefox 90+ |
| Mobile iOS | iOS 14+ |
| Mobile Android | Android 10+ (API 29) |
| Screen | Min 375px width (web), all phone sizes (mobile) |

---

## 5. GPS Device Support (v1.0.0 — Thai Market)

| Protocol | Port | Device | Priority |
|----------|------|--------|---------|
| Teltonika | 5023 | FMB920, FMB140, FMC003 | P0 — Thai fleet standard |
| GT06/GT02 | 5093 | Coban GPS103, TK303 | P0 — Most common budget |
| OsmAnd | 5055 | Smartphone tracker | P0 — Delivery riders |
| Queclink | 5027 | GV55, GV75 | P1 |
| Ruptela | 5013 | FM-ECO4+ | P1 |
| Meitrack | 5082 | MVT800, TC68L | P1 |
| TK103/Xexun | 5007 | Budget trackers | P2 |
| Wialon IPS | 5044 | Enterprise | P2 |

---

## 6. Business Requirements

### 6.1 Pricing (v1.0.0)
| Plan | ราคา/คัน/เดือน | Features |
|------|----------------|---------|
| Basic | ฿200 | Live tracking, history 30 days, basic alerts |
| Fleet | ฿350 | + Geofencing, reports, mobile app |
| Pro | ฿500 | + API access, LINE Notify, 90-day history |

### 6.2 SLA Target
- Uptime: 99.5% (ยอมรับ downtime 3.6h/เดือน สำหรับ v1.0.0)
- ไม่มี maintenance window ในชั่วโมงทำงาน (06:00-22:00 ICT)

### 6.3 Support
- LINE Official Account สำหรับ support
- เอกสาร Thai คู่มือการใช้งาน (v1.0.0 milestone)

---

## 7. Implementation Checklist — สิ่งที่ต้องทำก่อน Launch

### 🔴 P0 — Blocker (ต้องเสร็จก่อน launch)

#### Infrastructure
- [ ] **สร้าง GCP VM** — e2-standard-4, asia-southeast1-a
  ```bash
  gcloud compute instances create bellerox-gps-vm \
    --zone=asia-southeast1-a --machine-type=e2-standard-4 \
    --image-family=debian-12 --image-project=debian-cloud \
    --boot-disk-size=50GB --boot-disk-type=pd-ssd
  ```
- [ ] **รัน setup-server.sh** บน VM
- [ ] **ตั้ง DNS** `traccar.gps.bellerox.com → <VM_IP>` (gray cloud)
  ```bash
  CF_API_TOKEN=<full-token> GCP_VM_IP=<ip> bash infrastructure/scripts/dns-setup.sh
  ```
- [ ] **Deploy Docker stack** `docker-compose up -d`
- [ ] **สร้าง admin account**
  ```bash
  bash infrastructure/scripts/create-admin.sh
  ```
  - Email: `admin@bellerox.com`
  - Password: `AdminGPS123=!`
- [ ] **ผูก custom domain** `gps.bellerox.com` ใน Cloudflare Pages dashboard

#### Web App
- [ ] ทดสอบ login ด้วย admin@bellerox.com จริง
- [ ] ทดสอบ WebSocket real-time กับ Traccar server จริง
- [ ] ทดสอบ Longdo Map API key (e4e9be1dbdc29a63c81f834251b14de1)
- [ ] ตั้ง `VITE_TRACCAR_API_URL=https://api.gps.bellerox.com` ใน CF Pages env
- [ ] ตั้ง `VITE_TRACCAR_WS_URL=wss://api.gps.bellerox.com/api/socket` ใน CF Pages env
- [ ] ตั้ง `VITE_LONGDO_MAP_KEY=e4e9be1dbdc29a63c81f834251b14de1` ใน CF Pages env

#### Mobile
- [ ] ลงทะเบียน Expo / EAS account
- [ ] `eas build --platform all` สร้าง production build
- [ ] ทดสอบบน iOS simulator และ Android emulator
- [ ] Submit ใน App Store และ Google Play (ใช้เวลา 3-7 วัน review)

### 🟡 P1 — Important (เสร็จ week 2)

- [ ] ตั้ง Cloudflare API token แบบ Full Access (ดู docs/cloudflare-token-guide.md)
- [ ] เชื่อม LINE Notify token ให้ alert rules ทำงานได้จริง
- [ ] Push notification บน mobile (Expo Notifications)
- [ ] ทดสอบ GPS device จริง 1 ตัว (Teltonika หรือ GT06)
- [ ] Load test 100 vehicles (ใช้ Traccar demo data)
- [ ] เปิด GCP Cloud Monitoring alerts (disk > 80%, memory > 90%)

### 🟢 P2 — Nice to have (เสร็จ week 3-4)

- [ ] Geofence drawing UI บนแผนที่
- [ ] Trip replay animation
- [ ] Marker clustering สำหรับ 500+ vehicles (`react-leaflet-cluster`)
- [ ] Driver behavior scoring dashboard
- [ ] เอกสารคู่มือผู้ใช้ภาษาไทย (PDF)
- [ ] Video demo (Loom/YouTube)
- [ ] Landing page บน bellerox.com

---

## 8. Definition of Done — v1.0.0 Complete

Version 1.0.0 ถือว่า complete เมื่อ:

1. ✅ GCP VM running, Traccar live at `traccar.gps.bellerox.com`
2. ✅ Web app live at `gps.bellerox.com` (custom domain ผูกแล้ว)
3. ✅ `api.gps.bellerox.com` Cloudflare Worker proxy live
4. ✅ admin@bellerox.com login ได้จริง
5. ✅ GPS device อย่างน้อย 1 ตัว ส่ง position เข้า Traccar ได้
6. ✅ Live map แสดง marker ของยานพาหนะนั้น
7. ✅ Mobile app build ผ่าน EAS ได้ (iOS + Android)
8. ✅ รายงาน trip แสดงข้อมูลถูกต้อง
9. ✅ LINE Notify ส่ง alert ได้เมื่อ GPS overspeed
10. ✅ `npm run build` zero errors · `npm run lint` zero warnings

---

## 9. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| GPS device ที่ลูกค้าใช้ไม่รองรับ protocol | Low | High | Traccar รองรับ 200+ protocols · เปิด port ครบแล้ว |
| GCP VM crash (single point of failure) | Medium | High | Snapshot backup daily · restore < 2h |
| LINE Notify API rate limit | Low | Low | 1000 req/hour per token — เพียงพอสำหรับ v1.0.0 |
| App Store rejection (mobile) | Medium | Medium | ทดสอบ guidelines ก่อน submit |
| Thai PDPA compliance | Low | High | Driver consent banner ใน mobile app |
| Cloudflare outage | Very Low | High | Traccar ยังเข้าได้ตรงผ่าน `traccar.gps.bellerox.com` |

---

## 10. Success Metrics (30 วันหลัง launch)

| Metric | Target |
|--------|--------|
| Paying customers | 3+ fleet operators |
| Vehicles tracked | 50+ vehicles |
| DAU web app | 5+ users/day |
| Mobile installs | 20+ |
| System uptime | > 99% |
| Support tickets | < 5/week |
| NPS score | > 40 |

---

## Appendix: Tech Stack Summary

| Layer | Technology | Version |
|-------|-----------|---------|
| GPS Core | Traccar | 6.14.5 |
| Database | PostgreSQL | 16 |
| Cache | Redis | 7 |
| Web App | React + Vite + TypeScript | 18 / 5 / 5.x |
| Styling | Tailwind CSS | 3.x |
| Map | Leaflet + react-leaflet | 1.9 / 4.x |
| State | React Query + Zustand | v5 / v4 |
| Mobile | Expo SDK + React Native | 51 / 0.74 |
| Deploy: Web | Cloudflare Pages | — |
| Deploy: API proxy | Cloudflare Workers | — |
| Deploy: Backend | GCP Compute Engine | e2-standard-4 |
| Domain | Cloudflare (bellerox.com) | — |
| Thai geocoding | Longdo Map API | v2 |

---

*PRD Owner: Bellerox Product Team · Review by: Engineering + Business*  
*Next review: 30 วันหลัง launch หรือเมื่อ KPI ไม่เป็นไปตามเป้า*
