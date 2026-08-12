# Geocoding API Comparison — 20,000 คัน GPS Tracking

> **Use case:** Reverse geocoding (lat/lng → address) สำหรับ trip reports
> **Scale:** 20,000 คัน × 10 trips/day × 2 addresses (start+end) = **400,000 requests/day**
> **Region focus:** Thailand (ต้องได้ที่อยู่ไทยระดับถนน/ตำบล/อำเภอ)

---

## 📊 API Comparison

| Provider | Free Quota | Paid Price | Quality (Thailand) | Rate Limit | Notes |
|----------|-----------|------------|-------------------|-----------|--------|
| **Nominatim (OSM)** | Unlimited (fair use) | ฿0 | ⭐⭐⭐ Good | 1 req/sec | ฟรีตลอด แต่ช้า + ต้อง self-host ถ้าใช้เยอะ |
| **Google Maps** | $200/month credit | $5/1000 req | ⭐⭐⭐⭐⭐ Excellent | No limit | แพงที่สุด แต่คุณภาพดีที่สุด |
| **Longdo Map** | 10,000/day | ฿0.50/1000 req | ⭐⭐⭐⭐⭐ Excellent (Thai) | 10 req/sec | **ถูกที่สุดสำหรับไทย** |
| **LocationIQ** | 5,000/day | $1/1000 req | ⭐⭐⭐ Good | 2 req/sec | ใช้ OSM data + พี่เลี้ยง |
| **Mapbox** | 100,000/month | $4/1000 req | ⭐⭐⭐⭐ Very Good | No limit | Global ดี แต่ไทยไม่แม่นเท่า Longdo |
| **HERE** | 250,000/month | $1/1000 req | ⭐⭐⭐⭐ Very Good | No limit | Enterprise-grade |
| **Opencage** | 2,500/day | $50/month (25k) | ⭐⭐⭐ Good | 1 req/sec | Aggregator (OSM + others) |

---

## 💰 Cost Calculation (400,000 requests/day)

| Provider | Monthly Requests | Monthly Cost (THB) | Annual Cost (THB) |
|----------|-----------------|-------------------|------------------|
| **Nominatim (OSM)** | 12M | ฿0 | ฿0 |
| **Longdo Map** | 12M | ฿6,000 | ฿72,000 |
| **LocationIQ** | 12M | ฿36,000 | ฿432,000 |
| **HERE** | 12M | ฿36,000 | ฿432,000 |
| **Mapbox** | 12M | ฿144,000 | ฿1,728,000 |
| **Google Maps** | 12M | ฿180,000 | ฿2,160,000 |

> 💡 **1 THB ≈ $0.03 USD** (exchange rate used: 33 THB/USD)

---

## 🏆 Recommendation: Longdo Map

### ✅ Why Longdo Map?

1. **ถูกที่สุดสำหรับไทย** — ฿6,000/month (vs Google ฿180,000/month)
2. **คุณภาพดีที่สุดในไทย** — มีข้อมูลระดับซอย/หมู่บ้าน/ตำบล ครบกว่า Google
3. **Thai-first** — ชื่อถนนเป็นภาษาไทย แม่นยำกว่า OSM
4. **Free tier 10k/day** — ทดสอบฟรี 10,000 requests/day ก่อน
5. **Fast response** — API server ใน Thailand (latency ต่ำ)

### 📋 Longdo API Example

```typescript
// Reverse Geocoding API
const url = `https://api.longdo.com/map/services/address?lon=${lng}&lat=${lat}&key=${LONGDO_API_KEY}`;
const response = await fetch(url);
const data = await response.json();
// Response: { subdistrict, district, province, geocode, postcode, ... }
```

**Sample Response:**
```json
{
  "subdistrict": "ลาดยาว",
  "district": "จตุจักร",
  "province": "กรุงเทพมหานคร",
  "road": "ถนนพหลโยธิน",
  "geocode": "10900",
  "postcode": "10900"
}
```

---

## 🥈 Alternative: Nominatim (ฟรี) + Cache Strategy

ถ้าไม่อยากเสียเงิน:

1. **Self-host Nominatim** — ติดตั้ง Nominatim server บน GCP VM
2. **Import Thailand OSM data only** — ลด storage + เร็วขึ้น
3. **Aggressive caching** — cache ผลลัพธ์ถาวรใน PostgreSQL (lat/lng → address ไม่เปลี่ยน)
4. **Rate limit safely** — max 1 req/sec เมื่อใช้ public Nominatim

**Setup cost:**
- GCP VM e2-medium: ~฿1,500/month
- 100GB SSD: ~฿600/month
- **Total:** ~฿2,100/month (ประหยัดกว่า Longdo นิดนึง แต่ต้อง maintain เอง)

---

## 🚨 DON'T Use Google Maps Geocoding

**Why?**
- **แพงเกินไป:** ฿180,000/month = 30× Longdo
- **Overkill:** คุณภาพดีเกินความจำเป็น (global-scale ใช้สำหรับไทยอย่างเดียว)
- **Quota management:** ต้องระวัง overage (bill แพงขึ้นไม่รู้ตัว)

---

## 📋 Next Steps

### Option A: ใช้ Longdo Map (แนะนำ)
1. สมัคร Longdo Map API key → https://map.longdo.com/developers
2. แก้ `traccar.xml` ให้ใช้ Longdo geocoding
3. หรือ แก้ frontend ให้เรียก Longdo เมื่อ `startAddress === 'TH'`

### Option B: Self-host Nominatim (ฟรี แต่ต้อง maintain)
1. ติดตั้ง Nominatim server บน GCP VM
2. Import Thailand OSM data (pbf file)
3. Config Traccar ให้ใช้ Nominatim URL ของเรา

### Option C: ใช้ Nominatim public (ฟรี แต่ช้า)
1. Rate limit 1 req/sec → 400k requests/day ต้องใช้เวลา ~4.6 วัน
2. ไม่เหมาะสำหรับ real-time reports

---

## 🎯 Final Recommendation

**20,000 คัน → ใช้ Longdo Map**
- ฿6,000/month = 0.3% of revenue (20k คัน × ฿35/คัน = ฿700k/month)
- คุณภาพดีที่สุดในไทย
- ไม่ต้อง maintain server เอง
- เริ่มต้นฟรี 10k requests/day (ทดสอบก่อน)

**< 2,000 คัน → ใช้ Nominatim public ฟรี**
- 2,000 คัน × 20 addresses/day = 40k requests/day
- อยู่ในเกณฑ์ free tier ของ Nominatim (fair use)
- ใช้ cache + queue ลด request

---

**Created:** 2026-08-12  
**Scale:** 20,000 vehicles  
**Decision:** Longdo Map (฿6k/month) > Nominatim self-host (฿2.1k/month + maintenance) > Google Maps (฿180k/month)
