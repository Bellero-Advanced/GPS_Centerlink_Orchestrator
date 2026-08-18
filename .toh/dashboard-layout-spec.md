# Dashboard Layout Specification — จากภาพ 14

## Overall Layout (100vh)

```
[Header: 4 KPI cards] — 120px height
├─ ภาพรวม: 139 คัน (สีชมพู)
├─ ออนไลน์: 70 คัน (สีเขียว)
├─ เคลื่อนที่: 7 คัน (สีส้ม)
└─ ออฟไลน์: 69 คัน (สีแดง)

[Main Content: 2-column layout] — calc(100vh - 240px)
├─ Left Column (70%) — Vehicle Table
│  ├─ Search bar + filters (top)
│  └─ Table (scrollable)
│
└─ Right Column (30%) — 2 cards stacked
   ├─ Card 1: สัดส่วนสถานะ (Donut Chart)
   │  ├─ Chart center: "139 คัน"
   │  └─ Legend: 
   │     - เคลื่อนที่: 9 (6%)
   │     - จอดติดเครื่อง: 1 (1%)
   │     - จอดดับเครื่อง: 60 (43%)
   │     - ออฟไลน์: 69 (50%)
   │
   └─ Card 2: FLEET HEALTH SCORE
      ├─ Score: 37 (สีแดง — ต่ำ)
      ├─ Progress bar (red)
      └─ Text: "ครบเหมาะจาก 100 หากเหมาะสม"
      └─ Sub: "การคำนวณคะแนน (100 คะแนน)
              ออนไลน์ <50 + เคลื่อนที่ <30 + ไม่ออฟไลน์ <20"

[Bottom: 3-column stats] — Fixed 120px height
├─ ระยะทางรวมวันนี้: 1,284 กม.
├─ ประสิทธิภาพน้ำมันรวม: 50% (แถบสีส้ม)
└─ ยานพาหนะวันนี้: 70 / 139 คัน
```

## Component Breakdown

### 1. Donut Chart (Recharts PieChart)
- **Size:** 200px × 200px
- **Inner radius:** 70px
- **Outer radius:** 90px
- **Colors:**
  - เคลื่อนที่: #34A853 (green)
  - จอดติดเครื่อง: #FBBC04 (amber)
  - จอดดับเครื่อง: #EA4335 (red)
  - ออฟไลน์: #9AA0A6 (gray)
- **Center text:** "139 คัน" (28px bold)
- **Legend:** 4 rows, dot + label + count + percentage

### 2. Fleet Health Score Card
- **Score display:** 
  - Number: 72px font, bold, red (#EA4335) if < 50, amber if 50-75, green if > 75
  - Label: "ต่ำจนถึง" / "พอใช้" / "ดี"
- **Progress bar:**
  - Width: 100%
  - Height: 8px
  - Filled width: score%
  - Color: matches score color
- **Formula text:** 12px, gray
  "การคำนวณคะแนน (100 คะแนน)
   ออนไลน์ <50 + เคลื่อนที่ <30 + ไม่ออฟไลน์ <20"

### 3. Bottom Stats Cards (3-column)
Each card:
- **Icon:** 20px, colored
- **Value:** 32px, bold, mono font
- **Label:** 14px, gray
- **Sub-label:** 12px (if applicable)

**Card 1 — ระยะทางรวมวันนี้**
- Icon: Map (blue)
- Value: "1,284" + "กม."
- Calculation: sum of all vehicle distances today (mock for now)

**Card 2 — ประสิทธิภาพน้ำมันรวม**
- Icon: Fuel (orange)
- Value: "50%"
- Progress bar: orange, 50% filled
- Calculation: mock (real would be fuel consumed / distance)

**Card 3 — ยานพาหนะวันนี้**
- Icon: Truck (green)
- Value: "70 / 139" + "คัน"
- Calculation: vehicles with movement today / total

## Grid Structure

```css
/* Main 2-column */
.dashboard-grid {
  display: grid;
  grid-template-columns: 70% 30%;
  gap: 20px;
  height: calc(100vh - 240px);
}

/* Right column: 2 cards stacked */
.right-column {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Bottom 3-column */
.bottom-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  height: 120px;
}
```

## Colors Reference (from image)
- Background: #F8F9FA
- Card: #FFFFFF
- Pink KPI bg: #FCE4EC
- Green KPI bg: #E8F5E9
- Orange KPI bg: #FFF3E0
- Red KPI bg: #FFEBEE
- Score red: #EA4335
- Score amber: #FBBC04
- Score green: #34A853

## Tasks
1. Create DonutChart component (Recharts)
2. Create HealthScoreCard component
3. Create BottomStatsCard component
4. Rebuild DashboardPage with 2-column + bottom layout
5. Calculate real health score from vehicle data
