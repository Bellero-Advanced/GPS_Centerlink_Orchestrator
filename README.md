# Bellerox GPS — Transportation Management System

> ระบบติดตาม GPS และบริหารจัดการยานพาหนะสำหรับธุรกิจขนส่งไทย
> Scale: 4,000 → 100,000 vehicles · Deploy: gps.bellerox.com

## 🆕 **Payment System (Slot-based Decimal Tagging)**

**NEW:** Automated payment processing with 99-slot pool system

- ✅ **Auto-match payments** via decimal tagging (e.g., ฿210.47 → device #47)
- ✅ **99 concurrent payments** without collision
- ✅ **Queue system** when slots full (< 1% probability)
- ✅ **FREE** — uses standard PromptPay (no QR30 fees)
- 📖 **Docs:** See `docs/PAYMENT-SYSTEM.md` for full details

**Setup:**
```bash
# 1. Run migrations
supabase db push

# 2. Set environment variables
echo "VITE_PROMPTPAY_ID=0315562001168" >> bellerox-gps-web/.env.local

# 3. Deploy webhook handler
cd infrastructure/cloudflare/workers
wrangler deploy promptpay-webhook.ts

# 4. Deploy Edge Function
supabase functions deploy payment-reconcile
```

**Company Account:**
- Bank: Krungthai (กรุงไทย)
- Account: 0170777294
- Tax ID: 0315562001168
- Branch: เซ็นทรัลลาดพร้าว (690)

---

## Architecture

```
GPS Devices (Teltonika, GT06, OsmAnd...)
    └─► Traccar Server (Java, GCP asia-southeast1)
            └─► PostgreSQL (position history)
            └─► REST API :8082

Bellerox GPS Web App (React + Vite)
    → gps.bellerox.com (Cloudflare Pages)
    → Calls api.gps.bellerox.com (Cloudflare Worker proxy)
    → Worker proxies to traccar.gps.bellerox.com (GCP VM)
```

## Project Layout

```
gps_thailand_application/
├── traccar-other-6.14.5/       ← Traccar Server binary (DO NOT MODIFY)
├── bellerox-gps-web/           ← Web App (React + Vite + TypeScript)
├── bellerox-gps-mobile/        ← Mobile App (Expo React Native — TODO)
├── infrastructure/
│   ├── docker/
│   │   ├── docker-compose.yml  ← All services (Traccar + Postgres + Redis + Nginx)
│   │   ├── traccar/
│   │   │   └── traccar.xml     ← Traccar config (PostgreSQL, Thai protocols)
│   │   ├── postgres/
│   │   │   └── init.sql        ← DB init + performance tuning
│   │   └── nginx/
│   │       └── nginx.conf      ← SSL reverse proxy
│   ├── cloudflare/
│   │   ├── wrangler.toml       ← CF Worker config
│   │   └── workers/
│   │       └── traccar-proxy.ts ← API proxy Worker
│   ├── gcp/
│   │   └── terraform/          ← GCP infrastructure as code
│   └── scripts/
│       ├── setup-server.sh     ← First-time VM setup
│       ├── deploy.sh           ← Deploy/update
│       └── backup.sh           ← PostgreSQL backup to GCS
└── CLAUDE.md
```

## Quick Start

### 1. Local Development (without a cloud server)

```bash
# Start Traccar + Postgres locally via Docker
cd infrastructure/docker
cp ../.env.example .env
# Edit .env — set POSTGRES_PASSWORD

docker compose up -d

# Traccar web UI: http://localhost:8082
# Create admin account on first visit

# Start web app
cd ../../bellerox-gps-web
cp .env.example .env.local
# Edit .env.local — set VITE_TRACCAR_API_URL=http://localhost:8082

npm install
npm run dev
# → http://localhost:5173
```

### 2. Production Deployment (GCP)

```bash
# Step 1: Create GCP VM (e2-standard-4, asia-southeast1-a)
# Step 2: Point DNS → VM IP (traccar.gps.bellerox.com → <VM_IP>)
# Step 3: SSH into VM and run setup:
bash infrastructure/scripts/setup-server.sh

# Step 4: Copy files to VM, create .env, start services:
cd infrastructure/docker
cp ../.env.example .env  # fill in real passwords
docker compose up -d

# Step 5: Deploy Cloudflare Worker (api.gps.bellerox.com):
cd infrastructure/cloudflare
npx wrangler deploy

# Step 6: Deploy web app to Cloudflare Pages (gps.bellerox.com):
cd bellerox-gps-web
npm run build
npx wrangler pages deploy dist --project-name=bellerox-gps
```

## Traccar Protocols (Thai Market)

| Protocol | Port | Common Devices |
|----------|------|----------------|
| Teltonika | 5023 | FMB920, FMB140, FMC003 |
| GT06/GT02 | 5093 | Coban, TK303, many Chinese clones |
| OsmAnd | 5055 | Android/iOS phone-as-tracker |
| Queclink | 5027 | GV55, GV57, GV75 |
| Ruptela | 5013 | FM-ECO4+ |
| Meitrack | 5082 | MVT800, T1 |

## Web App Stack

- **React 18** + TypeScript + Vite 5
- **Tailwind CSS 3** — Thai-friendly fonts (Sarabun + Inter)
- **React Query** — GPS data fetching with 10s auto-refresh
- **Zustand** — Auth state
- **Leaflet + react-leaflet** — Map rendering
- **Lucide React** — Icons

## Domain + DNS

| Record | Type | Target |
|--------|------|--------|
| `gps.bellerox.com` | CNAME | Cloudflare Pages |
| `api.gps.bellerox.com` | Worker route | CF Worker proxy |
| `traccar.gps.bellerox.com` | A | GCP VM IP |

## Scaling Notes

| Vehicles | Recommended Setup |
|----------|-------------------|
| 0–5k | e2-standard-2 (2vCPU, 8GB) + Cloud SQL PostgreSQL |
| 5k–20k | e2-standard-4 (4vCPU, 16GB) + Cloud SQL |
| 20k–100k | GKE Autopilot (Traccar cluster) + Cloud SQL Enterprise |
| 100k+ | GKE + TimescaleDB + Pub/Sub |

## License

Traccar is open-source (Apache 2.0) — https://www.traccar.org/license/
Bellerox GPS custom code — Proprietary
