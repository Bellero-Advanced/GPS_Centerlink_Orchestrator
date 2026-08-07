# Bellerox GPS — Product Strategy
# Thai → APAC → Global

## Vision
Build the **Samsara for Southeast Asia** — beautiful, fast, reliable GPS fleet management
that starts in Thailand and grows to serve fleets across APAC and eventually globally.

## Phase 1: Thailand (Current)
**Target**: 50 enterprise fleet customers, 10,000 vehicles under management
**Timeline**: 6 months from launch

**Focus features:**
- Live map tracking (done ✅)
- Fleet management (vehicles, groups)
- Trip history + route playback
- Geofencing (zones + alerts)
- Driver behavior scoring
- Thai language + Longdo Map
- Mobile app (iOS + Android)
- Speeding/idle/ignition alerts

**Sales motion:**
- Direct B2B sales in Thailand
- Pricing: ฿30/vehicle/month (Basic), ฿35/vehicle/month (Pro)
- Minimum contract: 6 months (collected upfront or monthly)
- Free 30-day trial before contract
- No setup fee

## Phase 2: APAC Expansion (Month 7-18)
**Target**: Vietnam, Indonesia, Philippines, Malaysia

**Required for APAC:**
- Multi-language (EN, TH, VI, ID, TL, MS)
- Multi-currency (THB, VND, IDR, PHP, MYR, SGD)
- Multi-timezone display
- APAC GPS device protocol support
- Localized address format per country
- Google Maps (primary for APAC beyond Thailand)
- Payment: credit card + local gateways (GrabPay, GoPay)

## Phase 3: Global (Month 18+)
**Target**: Australia, Middle East, Africa (emerging markets)

**Required for Global:**
- ISO/IEC compliance
- GDPR compliance (EU data)
- ELD/HOS for North America (if needed)
- Enterprise SSO (SAML, OIDC)
- White-label/reseller program
- Dedicated cloud regions (AWS us-east, eu-west)

## Product Principles (never compromise)

1. **Fast map** — The map must load in < 2 seconds, markers update in < 1 second
2. **Thai-first UX** — Sarabun font, Thai labels, Thai date format, Thai address
3. **Mobile-grade** — Must work perfectly on tablet and phone (fleet managers are on the road)
4. **API-first** — Every feature accessible via API (enables integrations with ERP/WMS)
5. **99.9% uptime** — Vehicle tracking is safety-critical. No maintenance windows during business hours.

## Pricing Model (SaaS per vehicle — 6-month contract minimum)
| Plan | Price/vehicle/month | Contract | Features |
|------|--------------------|-|---------|
| Basic | ฿30 | 6 months (฿180/vehicle) | Live tracking, history 30 days, basic alerts |
| Pro | ฿35 | 6 months (฿210/vehicle) | + Geofencing, driver scoring, reports, mobile, API |
| Enterprise | Custom | Annual | White-label, dedicated infra, SLA, integrations |

> **Contract structure:** Minimum 6-month commitment.
> Basic ฿30×6 = ฿180 upfront per vehicle. Pro ฿35×6 = ฿210 upfront per vehicle.

## Key Integrations to Build (roadmap)
1. **JINKIN ERP** — Link vehicles to job orders (natural integration with sister product)
2. **LINE Notify** — Thai businesses use LINE for alerts (not email)
3. **Grab/Foodpanda API** — Sync delivery orders with GPS route
4. **Thai customs** — Border crossing alerts for cross-border trucking
5. **Google Workspace** — Fleet reports to Google Sheets/Drive
6. **Shopify/WooCommerce** — Last-mile delivery tracking for e-commerce

## Technical Differentiation
- Traccar core = 200+ protocols = any GPS device works (vs competitors lock-in)
- Real-time < 500ms (vs competitors 30-60 second delays)
- OpenStreetMap + Longdo = no Google Maps cost for basic tiers
- Self-hostable option for enterprise (on-premise deployment)
