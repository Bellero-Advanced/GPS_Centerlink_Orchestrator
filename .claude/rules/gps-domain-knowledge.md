# GPS & Fleet Management Domain Knowledge
# World-class reference for building GPS tracking systems
# Thai → APAC → Global strategy

## GPS Technology Fundamentals

### How GPS Tracking Works (End-to-End)
```
GPS Satellite → GPS Device (in vehicle)
    → GPS Device embeds position in proprietary protocol packet
    → Packet sent via GPRS/3G/4G/LTE TCP connection to Traccar server
    → Traccar decodes protocol → stores position in PostgreSQL
    → WebSocket pushes to connected web clients (< 500ms latency)
    → React app updates map marker
```

### Position Data Fields (critical for fleet intelligence)
| Field | Meaning | Business Use |
|-------|---------|--------------|
| `latitude/longitude` | GPS coordinates | Map display, geofencing |
| `speed` | Current speed (knots → km/h) | Speeding alerts, driver scoring |
| `course` | Heading direction (0-360°) | Route direction arrow |
| `altitude` | Height in meters | Mountain/hill detection |
| `accuracy` | GPS accuracy in meters | Filter bad positions |
| `attributes.ignition` | Engine on/off | Idle time, unauthorized use |
| `attributes.motion` | Motion sensor | Stop/moving detection |
| `attributes.odometer` | Total km (from device) | Maintenance scheduling |
| `attributes.fuel` | Fuel level % | Fuel consumption reports |
| `attributes.rpm` | Engine RPM | Driver behavior |
| `attributes.batteryLevel` | Device battery | Device health monitoring |
| `attributes.hours` | Engine hours (seconds) | Service intervals |

## GPS Device Protocols — Comprehensive Guide

### Thai Market (in order of market share)

**1. Teltonika (FMB series) — Professional choice**
- Port: 5023
- Market share Thailand: ~40% of professional fleets
- Models: FMB920, FMB140, FMB641, FMC001, FMC003, FMB003
- Features: Accelerometer, CAN bus, fuel, harsh driving detection
- Price: 2,000-8,000 THB
- Best for: Trucks, logistics fleets

**2. GT06/GT02/Concox — Budget trackers**
- Port: 5093
- Market share: ~35% (cheap, widely sold in Thailand)
- Models: Coban GPS103, TK303, GPS303, JM-LL01
- Features: Basic GPS + ignition, some with fuel
- Price: 300-1,500 THB
- Best for: Small fleets, motorcycles, personal vehicles

**3. Queclink (GL/GV series)**
- Port: 5027
- Market: ~10% professional
- Models: GV55Lite, GV57, GV75, GL300
- Features: 4G LTE, multiple I/O, CAN bus
- Price: 3,000-10,000 THB

**4. OsmAnd (phone-as-tracker)**
- Port: 5055
- Market: ~5% (BYOD fleets, delivery riders)
- Platform: Android/iOS app free
- Use case: Delivery fleets that use smartphones anyway

**5. Meitrack**
- Port: 5082
- Market: ~5% SE Asia
- Models: MVT800, T1, TC68L
- Good for: Cold chain (temp sensor), maritime

**6. iStartek (VT900 series) — confirmed production use**
- Port: **5009** (meiligao protocol — VT900 2G/3G, BCD-encoded device ID)
- Alt ports: 5143 (vt200 binary), **5222** (startek — VT900-L 4G LTE, ASCII IMEI)
- Market: Growing adoption in Thailand (budget 4G trackers)
- Models: VT900 (2G/3G), VT900-L (4G LTE), VT900-G
- Features: GPS + ignition, basic I/O
- Price: 800–2,500 THB
- Note: Firmware generation determines protocol — VT900 2G/3G → meiligao (5009);
  VT900-L 4G → startek (5222). uniqueId in Traccar is BCD-derived (12 digits, no leading zeros).
  All 3 ports (5009, 5143, 5222) must be open in firewall to cover the full VT900 family.

### APAC Market Additions
- **Jointech (JT series)** — Southeast Asia popular
- **LKGPS/Concox** — China-made, widespread SEA
- **CalAmp (USA)** — Enterprise ANZ market
- **Navman** — Australia/NZ fleets
- **Mobilaris** — Industrial (mining, Nordic)
- **Syrus (Digital Matter)** — ANZ/SA

### Global Market
- **Calamp** — US logistics
- **Geotab** — North America enterprise standard
- **Webfleet (TomTom)** — Europe fleet standard
- **Samsara** — US, fastest growing enterprise
- **Spireon** — US trucking

## Fleet Management Business Logic

### Vehicle States (critical to get right)
```
MOVING   — speed > 2 km/h AND ignition ON
IDLE     — speed < 2 km/h AND ignition ON (wasting fuel)
STOPPED  — speed < 2 km/h AND ignition OFF
OFFLINE  — no data for > 5 minutes
TOWING   — speed > 5 km/h AND ignition OFF (theft indicator)
```

### Key Metrics to Track
**Per Vehicle:**
- Daily distance (km)
- Engine hours
- Idle time (cost = fuel burned while stopped)
- Trips today count
- Harsh braking events
- Overspeeding events
- Geofence violations
- Last known position age

**Per Fleet:**
- Fleet utilization rate (vehicles used / total)
- On-time delivery rate
- Average idle time %
- Fuel efficiency (L/100km)
- Safety score (0-100)

### Driver Behavior Scoring (industry standard)
Score starts at 100, deductions per event:
- Harsh acceleration: -2 points
- Harsh braking: -3 points
- Harsh cornering: -2 points
- Overspeeding > 20 km/h over limit: -5 points
- Overspeeding > 40 km/h over limit: -10 points
- Idle > 10 minutes: -1 point per 10 min

### Trip Detection Algorithm
A "trip" is defined as:
- Start: ignition ON OR speed > 2 km/h (first position)
- End: ignition OFF AND speed = 0 for > 3 minutes

Min trip distance: 200 meters (filter parking lot movements)

### Geofencing Business Rules
- **Zone types**: Warehouse, depot, customer site, restricted area, country border
- **Alert triggers**: Enter, exit, both, time-based (only alert if outside zone after 8pm)
- **Zone geometry**: Circle (most common), polygon (custom area), route corridor

## Thailand-Specific Knowledge

### Thai Road Rules (for alert configuration)
- Highway speed limit: 120 km/h (expressway), 90 km/h (rural highway)
- City speed limit: 80 km/h (main road), 60 km/h (urban)
- Common speeding threshold in Thai fleet ops: 100 km/h alert
- Toll roads: Don Mueang Tollway, Chalerm Maha Nakhon, Burapha Withi

### Thai Address Format
```
เลขที่ [number] ถนน [road] แขวง/ตำบล [district]
เขต/อำเภอ [amphoe] จังหวัด [province] [postcode]
```
- Use Longdo Map API for Thai geocoding (best Thai address quality)
- Nominatim is OK but sometimes wrong for rural Thailand

### Thai Business Context
- **Logistics companies**: Kerry, Flash, Ninja Van, J&T, BEST — all use GPS tracking
- **Fleet sizes common in Thailand**: 10-50 vehicles (SME), 100-1000 (enterprise)
- **Contract structure**: Usually monthly SaaS per vehicle (฿200-500/vehicle/month)
- **Key industries**: Construction equipment, agricultural transport, tourist buses, delivery vans, truck fleets

### Thai Regulations
- Thailand DOT requires GPS tracking on commercial vehicles > 6 wheels
- Public transport (bus, minivan) requires Department of Land Transport GPS compliance
- Hazardous materials transport requires special GPS logging
- Speed limiter required for trucks > 15 tons

## APAC Market Intelligence

### Market by Country (GPS SaaS penetration)
| Country | Market Maturity | Key Players | Opportunity |
|---------|----------------|-------------|-------------|
| Thailand | Medium | Thai GPS, iFleet, TrackingSolutions | High growth |
| Vietnam | Low | Few local players | Very high |
| Philippines | Low-Medium | TrackMate, Elabram | High |
| Indonesia | Medium | GPS Track, CariKendaraan | Very large market |
| Malaysia | Medium-High | WirelessCar, CarTrack | Mature |
| Singapore | High | CarTrack, FleetCare | Enterprise only |
| Australia | High | Navman, FleetComplete, Geotab | Enterprise |
| Japan | Very High | Panasonic, Pioneer, Navitime | Hard to enter |
| India | Growing | CarIQ, Uffizio, Axons | Huge market |

### APAC-Specific Requirements
- **Multi-language**: Thai, English, Vietnamese, Bahasa, Chinese (simplified)
- **Multi-currency**: THB, VND, IDR, MYR, SGD, AUD
- **Multi-timezone**: UTC+7 (TH), UTC+8 (SG,MY), UTC+9 (JP), UTC+10 (AEST)
- **Multiple map providers**: Longdo (TH), Google Maps (Global), Baidu (CN)
- **Payment methods**: Thai QR Code, GrabPay, GoPay, credit card

### APAC GPS Device Landscape
- Most fleets use Chinese-manufactured trackers (Concox, Coban, Jointech)
- LTE (4G) now standard (2G sunset in 2024 in SG, MY, AU)
- OBD trackers growing (plug into OBD-II port, easier install)
- EV tracking needs: battery level, charge status, range

## Architecture for Global Scale

### Position Ingestion Pipeline (100k+ vehicles)
```
GPS Device TCP streams
    → Load Balancer (L4, TCP-aware, GCP Cloud Load Balancer)
    → Traccar cluster (multiple pods in GKE, stateless for HTTP)
    → NOTE: TCP device connections must be sticky (session affinity by device ID)
    → PostgreSQL TimescaleDB (partitioned by device_id + time)
    → Redis pub/sub (live position broadcast)
    → WebSocket server → connected clients
```

### Data Volume at 100k Vehicles
- Position updates: 1 update per 10 seconds per vehicle = 10,000 positions/second
- Storage: ~150 bytes per position × 10k/sec = 1.5 MB/sec = ~130 GB/day
- With 90-day retention: ~12 TB (need partitioned table + data tiering)

### TimescaleDB for Positions (when upgrading from plain PostgreSQL)
```sql
-- Hypertable: auto-partitions by time
SELECT create_hypertable('positions', 'fix_time', chunk_time_interval => INTERVAL '1 day');
-- Continuous aggregate for fast dashboard
CREATE MATERIALIZED VIEW hourly_position_stats
WITH (timescaledb.continuous) AS
SELECT device_id, time_bucket('1 hour', fix_time) AS hour,
  max(speed) as max_speed, avg(speed) as avg_speed, count(*) as positions
FROM tc_positions GROUP BY device_id, hour;
```

### Multi-tenant Architecture (when adding SaaS customers)
- Each customer = a Traccar "group" (short term)
- Proper multi-tenant: separate Traccar instance per enterprise customer (isolation)
- SME customers: shared Traccar instance with group-level RLS
- Billing: Stripe Billing with per-vehicle metered usage

## Industry Standards & Compliance

### FMCSA (USA) ELD Mandate
- Electronic Logging Device required for US commercial trucks
- Hours of Service (HOS) tracking
- Not needed for Thailand initially, but required for Global

### ISO 15638 (GPS/telematics standard)
- International standard for fleet telematics data exchange
- Important for enterprise sales in EU/ANZ

### GDPR / PDPA (Thailand)
- PDPA (Personal Data Protection Act B.E. 2562) in Thailand
- Driver location = personal data
- Must have consent from drivers
- Data retention limits apply
- Right to deletion

## Competitive Analysis

### Direct Competitors
| Product | Market | Strength | Weakness |
|---------|--------|----------|---------|
| Thai GPS Tracker | Thailand | Local, cheap | Outdated UI, no API |
| iFleet (Thailand) | TH | Local support | Limited features |
| CarTrack | APAC | Enterprise features | Expensive |
| Geotab | Global | Most features | Complex, expensive |
| Samsara | US | Beautiful UX | US-only focus |
| Fleet Complete | APAC | Full TMS | Legacy tech |

### Bellerox GPS Positioning
- **Thai-first UX**: Thai language, Longdo Map, Thai address format
- **Modern stack**: Better UI than Thai competitors (built like Samsara)
- **Traccar-powered**: 200+ device protocols, no vendor lock-in
- **Open pricing**: Transparent ฿/vehicle/month
- **API-first**: Integrate with any Thai WMS/ERP (including JINKIN ERP!)

## Key APIs to Know

### Traccar REST API
- Full CRUD for devices, users, geofences
- Reports: trips, stops, summary, route
- Real-time: WebSocket `/api/socket`
- All docs: https://www.traccar.org/api-reference/

### Longdo Map API (Thai)
- Map tiles: `longdo.map.Layers.NORMAL`
- Geocoding: `https://api.longdo.com/map/json/address`
- Reverse geocoding: `https://api.longdo.com/map/json/geocode/reverse`
- Search: `https://search.longdo.com/mapsearch/json/search`
- Traffic layer: `longdo.map.Layers.TRAFFIC`
- Docs: https://api.longdo.com/map/doc/

### OBD-II Data (when using OBD trackers)
- PID 0x0C: Engine RPM
- PID 0x0D: Vehicle speed
- PID 0x04: Engine load %
- PID 0x05: Coolant temperature
- PID 0x2F: Fuel level
- PID 0x11: Throttle position
- PID 0xA6: Odometer
