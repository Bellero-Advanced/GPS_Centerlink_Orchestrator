# 📊 GPS Thailand Application — Cost Optimization Analysis & Action Plan

**วันที่:** 16 กันยายน 2026  
**วิเคราะห์โดย:** Claude (Toh Framework v3)  
**เป้าหมาย:** ลดต้นทุน GCP พร้อมเพิ่มประสิทธิภาพ

---

## 🎯 Executive Summary

### ปัญหาหลัก (Current State)
หนูตรวจสอบระบบจริงแล้วพบว่า:

1. **Over-Provisioned 4-5 เท่า** 
   - VM: n2-standard-2 (2 vCPU, 8GB RAM) แต่ใช้แค่ 1.4GB (18%)
   - CPU: ใช้งาน <0.5% (แทบไม่ได้ใช้เลย)
   - ค่าใช้จ่าย: **$97/เดือน** สำหรับ resource ที่ใช้แค่ 18%

2. **Frontend Polling สิ้นเปลือง**
   - Poll API ทุก 15 วินาที ไม่ว่าจะมี user ดูหรือไม่
   - ไม่ใช้ WebSocket (Traccar รองรับอยู่แล้ว)
   - API calls: ~240 requests/hour/user (มากเกินไป)

3. **Database ยังปรับแต่งได้**
   - Query time: 66ms (ยังโอเค แต่ทำได้ดีกว่า)
   - ไม่มี covering index → ต้อง heap lookup ทุกครั้ง
   - Retention 90 วัน แต่ใช้แค่ 7-30 วัน

4. **Redis ไม่ได้ใช้จริง**
   - Container running แต่ไม่มี traffic
   - เปลือง memory 64MB + CPU 0.11%

### ⚠️ ข้อมูลที่แก้ไข
Plan เดิมใน `.toh/plan.md` อิงตัวเลขคาดการณ์ แต่หนูตรวจสอบ production แล้วพบว่า:
- ❌ **ไม่ใช่** 500 คัน → จริง ๆ **214 คัน** active
- ❌ **ไม่ใช่** VM ขนาด e2-standard-4 ($97) → จริง ๆ **n2-standard-2** ($97)
- ✅ Position rate: 0.58/sec (ต่ำมาก, ไม่ใช่ทุก 30 วินาที)

---

## 💰 แนวทางลดต้นทุน (3 Phases)

### 📌 Phase 1: Frontend Optimization (ไม่มี Downtime, Impact สูงสุด)
**เป้าหมาย:** ลด API calls 60-70%, ลด egress cost $20/เดือน

#### ✅ Changes:
1. **React Query Cache Tuning**
   - Reports `staleTime`: 5 นาที → **10 นาที**
   - ไฟล์: `bellerox-gps-web/src/hooks/useReports.ts`
   - Impact: ลดการ refetch reports ลง 50%

2. **Nginx API Cache Layer** ⭐ ใหม่!
   - Cache `/api/reports/*` endpoint 5 นาที
   - เพิ่ม `X-Cache-Status` header (HIT/MISS)
   - ไฟล์: 
     - `infrastructure/docker/nginx/cache.conf` (config)
     - `infrastructure/docker/nginx/conf.d/traccar.conf` (rules)
   - Impact: Cache hit rate 60%+ → ลด Traccar load 60%

3. **WebSocket for Real-Time** (Optional Phase 1.5)
   - ใช้ `/api/socket` แทน polling ทุก 15 วินาที
   - ไฟล์: `bellerox-gps-web/src/hooks/useTraccarWebSocket.ts`
   - Impact: ลด API calls อีก 80% สำหรับ position updates

**Cost Savings Phase 1:** ~$20/เดือน (จาก egress)  
**Risk:** 🟢 LOW — cache + frontend only, ไม่กระทบ backend  
**Downtime:** 0 นาที (rolling deploy)

**Deployment:** 
```bash
# Frontend
cd bellerox-gps-web
npm run build && npx wrangler pages deploy dist

# Nginx
docker exec centerlink-nginx nginx -t
docker exec centerlink-nginx nginx -s reload
```

---

### 📌 Phase 2: VM Right-Sizing (Downtime 5-10 นาที)
**เป้าหมาย:** ลด VM cost จาก $97 → $50/เดือน (savings $47)

#### ⚠️ แก้ไขจาก Plan เดิม:
Plan เดิมบอก downsize เป็น **e2-small** ($15) แต่หนูวิเคราะห์แล้วเห็นว่า:
- e2-small (0.5 vCPU, 2GB RAM) เสี่ยงเกินไป สำหรับ 500 คัน (target)
- Memory budget แค่ 2GB แน่นเกินไป → risk OOM

#### ✅ แนะนำ: **e2-standard-2** (2 vCPU, 8GB RAM) → **$50/เดือน**
**เหตุผล:**
- Memory: 8GB → พอดีสำหรับ 500-1,000 คัน (75% utilization)
- CPU: 2 vCPU → รองรับ peak load ได้สบาย
- ค่าใช้จ่าย: $50 (ประหยัด $47/เดือน, 48% reduction)
- Risk ต่ำกว่า e2-small มาก

**Memory Allocation (8GB):**
```
PostgreSQL:    1.5 GB  (shared_buffers 512MB)
Traccar JVM:   2 GB    (heap -Xmx2g)
Nginx:         64 MB
System:        400 MB
Headroom:      4 GB    (50% free) ✅
```

**ไฟล์แก้:**
- `infrastructure/docker/docker-compose.yml` (memory limits)
- `infrastructure/docker/postgres/postgresql.conf` (shared_buffers)

**Cost Savings Phase 2:** $47/เดือน  
**Risk:** 🟡 MEDIUM — ต้อง stop VM, resize, restart  
**Downtime:** 5-10 นาที  

**Rollback Plan:** ไฟล์ `infrastructure/docs/phase2-vm-resize.md` (พร้อมแล้ว)

---

### 📌 Phase 3: Load Testing (ก่อน Phase 2)
**เป้าหมาย:** พิสูจน์ว่า e2-standard-2 รองรับ 1,000 คัน

#### Test Scenarios:
1. **Baseline:** 500 devices × 30s interval × 10 min
2. **Target:** 1,000 devices × 30s interval × 10 min
3. **Stress:** 1,500 → 2,000 → find breaking point

**Script:** `infrastructure/scripts/load-test-gps-devices.js` (Node.js, GT06 protocol)

**Pass Criteria:**
- CPU < 75%
- Memory < 80%
- Position lag < 10 seconds
- API error rate < 1%

**Cost:** $0 (test only, no production changes)  
**Risk:** 🟢 LOW  
**Duration:** 30-40 นาที total

---

### 📌 Phase 4: Database Optimization (Optional, Low Priority)
**เป้าหมาย:** Query time 66ms → <30ms

#### Changes:
1. **Covering Index**
   ```sql
   CREATE INDEX CONCURRENTLY idx_tc_positions_covering 
     ON tc_positions (deviceid, fixtime DESC) 
     INCLUDE (latitude, longitude, speed, course, address);
   ```
   - Impact: Index-only scan (no heap lookup) → 2× faster
   - Risk: 🟢 LOW (CONCURRENTLY = non-blocking)

2. **Retention Policy: 90 days → 30 days**
   - ลด disk usage: 1.6GB → 1.1GB (30% reduction)
   - Script: `infrastructure/scripts/cleanup-old-partitions.sh`
   - Risk: 🟢 LOW (can restore from backup)

**Cost Savings:** $0 (เพิ่มความเร็วอย่างเดียว)  
**Risk:** 🟢 LOW  
**Downtime:** 0 นาที

---

## 💸 สรุปต้นทุนทั้งหมด

| Item | Current | After Phase 1 | After Phase 2 | Savings |
|------|---------|---------------|---------------|---------|
| **Compute (VM)** | $97 | $97 | **$50** | **-$47** |
| **Egress (API calls)** | ~$80 | **$60** | $60 | **-$20** |
| **Storage** | included | included | included | - |
| **Total/Month** | **$177** | **$157** | **$110** | **-$67** |
| **Total/Year** | $2,124 | $1,884 | **$1,320** | **-$804** |

**ROI:** ประหยัด **$804/ปี** (38% reduction) ด้วยเวลา 4-6 ชั่วโมง

---

## ⚠️ สิ่งที่แก้ไขจาก Plan เดิม

| Plan เดิม | ความจริง | หนูแก้เป็น |
|-----------|----------|-------------|
| Target: e2-small ($15) | Too risky, 2GB RAM แน่นเกินไป | **e2-standard-2 ($50)** |
| Current: e2-standard-4 | จริง ๆ **n2-standard-2** | Updated docs |
| Vehicles: 500 | จริง ๆ **214 active** | Test ที่ 1,000 คัน |
| Position rate: ทุก 30s | จริง ๆ ~6 นาที/ครั้ง | ไม่กระทบ capacity |
| Redis: ใช้งาน | จริง ๆ **ไม่ได้ใช้** | ถอดออกได้ |

---

## 📋 Recommended Execution Order

### ✅ ลำดับที่ปลอดภัยที่สุด (แนะนำ):

```
Phase 1 (Frontend + Cache)
  → รอ 7 วัน (monitor)
    → Phase 3 (Load Test)
      → ถ้าผ่าน → Phase 2 (VM Resize)
        → รอ 7 วัน (monitor)
          → Phase 4 (Database) [optional]
```

### 🚀 Quick Wins (ทำได้เลย, 0 downtime):
1. ✅ Deploy frontend cache tuning (Phase 1.1)
2. ✅ Enable Nginx cache (Phase 1.2)
3. ✅ Monitor API calls drop 30%+
4. ✅ Verify cost reduction in GCP billing

**Timeline:** 1-2 ชั่วโมง, savings $20/เดือน

### 🎯 Full Optimization (รอ test ก่อน):
1. ✅ Phase 1 stable 7+ days
2. ✅ Run Phase 3 (load test)
3. ✅ If pass → Phase 2 (VM resize)
4. ✅ Monitor 7+ days
5. ✅ Optional: Phase 4 (database)

**Timeline:** 2-3 สัปดาห์, savings $67/เดือน

---

## 📁 ไฟล์ที่สร้างให้พี่โตแล้ว

### Configuration Files:
1. ✅ `infrastructure/docker/nginx/cache.conf` — Nginx cache zone config
2. ✅ `infrastructure/docker/nginx/conf.d/traccar.conf` — API cache rules
3. ✅ `infrastructure/docker/docker-compose.yml` — Updated memory limits + phase note

### Documentation:
1. ✅ `infrastructure/docs/phase1-deployment.md` — Frontend + cache deploy guide
2. ✅ `infrastructure/docs/phase2-vm-resize.md` — VM resize procedure (e2-standard-2)
3. ✅ `infrastructure/docs/phase3-load-testing.md` — Load test guide (1,000 devices)

### Scripts:
1. ✅ `infrastructure/scripts/load-test-gps-devices.js` — GPS device simulator (GT06)

### Analysis:
1. ✅ `.toh/infra-audit-report.md` — Current state analysis (already exists)
2. ✅ This file — Executive summary & action plan

---

## 🎯 แนะนำให้พี่โตทำ

### Option A: Conservative (ความเสี่ยงต่ำสุด)
**เริ่มจาก Phase 1 อย่างเดียว:**
1. Deploy frontend cache tuning (1 ชั่วโมง)
2. Enable Nginx cache (30 นาที)
3. รอ 1 เดือน → monitor cost reduction
4. ถ้าพอใจแล้ว → หยุดตรงนี้ (savings $20/เดือน)

**Pros:** เสี่ยงต่ำมาก, ไม่มี downtime  
**Cons:** ประหยัดน้อยกว่า ($20 vs $67)

### Option B: Balanced (แนะนำ) ⭐
**Phase 1 → Test → Phase 2:**
1. Deploy Phase 1 (frontend + cache)
2. รอ 7 วัน
3. Run Phase 3 (load test 1,000 คัน)
4. ถ้าผ่าน → Phase 2 (resize to e2-standard-2)
5. Total savings: **$67/เดือน**

**Pros:** Balance ระหว่าง savings และความเสี่ยง  
**Cons:** ต้อง downtime 5-10 นาที (Phase 2)

### Option C: Aggressive (ถ้าต้องการประหยัดสูงสุด)
**ทำทุก Phase:**
1. Phase 1 + 2 + 3 + 4 ภายใน 2 สัปดาห์
2. Target: e2-small ($15) แทน e2-standard-2
3. Total savings: **$82/เดือน**

**Pros:** ประหยัดสูงสุด  
**Cons:** เสี่ยงสูง, ต้องติดตามระบบใกล้ชิด

---

## ❓ คำถามสำหรับพี่โต

1. **Phase 1 (Frontend Cache):** พี่โตอยากให้หนู deploy ตอนนี้เลยไหม? (0 downtime, 1-2 ชั่วโมง)

2. **Phase 2 (VM Resize):** พี่โตโอเคกับ e2-standard-2 ($50) หรืออยากลองเสี่ยง e2-small ($15)?

3. **Timeline:** พี่โตรีบไหม? หรือจะทำทีละ phase แบบ conservative?

4. **Monitoring:** พี่โตมี GCP monitoring/alerting setup แล้วหรือยัง? (สำคัญสำหรับ Phase 2)

---

## ✅ Next Steps (รอพี่โตตอบ)

### ถ้าพี่โตอนุมัติ Phase 1:
```bash
# หนูจะทำทันที:
1. แก้ไข useReports.ts (staleTime 5m → 10m)
2. Deploy frontend to Cloudflare Pages
3. Enable Nginx cache
4. Verify cache working (X-Cache-Status header)
5. รอ 24 ชั่วโมง → รายงานผล (API calls ลดลงเท่าไหร่)
```

### ถ้าพี่โตอนุมัติ Phase 2:
```bash
# หนูจะทำตามลำดับ:
1. Run Phase 3 (load test) ก่อน
2. ถ้าผ่าน → Schedule VM resize (Saturday 02:00-03:00)
3. Execute migration (downtime 5-10 min)
4. Monitor 24 hours
5. รายงานผล (cost + performance)
```

---

**พี่โตต้องการให้หนูเริ่มจาก Phase ไหนก่อนครับ?** 🚀
