# 🚀 Bellerox GPS — Phase 7-10 Future Roadmap

**Status**: 
- Phase 7: 🔄 IN PROGRESS (เริ่ม 2026-08-24)
- Phase 8-10: 📋 PLANNING ONLY

**Created**: 2026-08-24  
**Updated**: 2026-08-24  
**Estimated Timeline**: Phase 7 (2 weeks) + Phase 8-10 (4-6 weeks) = ~6-8 weeks total

---

## 📊 Current Project Status (Phase 1-6)

### ✅ Completed (100%)
- **Phase 1-3**: GPS Tracking Core
  - Real-time vehicle tracking (10s refresh)
  - Trip reports, driver scoring, geofences
  - Monthly summary reports
  
- **Phase 4**: Activity Timeline Integration
  - 24-hour timeline visualization
  - Trip/idle/stopped segments with colors
  - PostgreSQL materialized view aggregation
  - API Gateway custom endpoint
  - **Performance**: 0.5s load time (95% improvement)

- **Phase 5**: Database Optimization
  - Materialized views for reports
  - Hourly refresh schedule
  - **Results**: 80% fewer API calls, 99% fewer database queries

- **Phase 6**: Security Hardening
  - Environment-based configuration
  - PostgreSQL SSL enforcement
  - CORS restrictions + rate limiting
  - Cookie-based authentication

### 🎯 Production Metrics
- **Activity timeline load**: 8-12s → **0.5s** (95% faster)
- **Monthly report load**: 15-20s → **2s** (90% faster)
- **API calls/day**: 50,000 → **10,000** (80% reduction)
- **Database queries/request**: 300+ → **1** (99% reduction)

---

## 🎯 Phase 7: Real-time WebSocket Integration

### Overview
เพิ่ม WebSocket server สำหรับการอัพเดทตำแหน่งรถแบบ real-time โดยไม่ต้อง polling ทุก 10 วินาที — ลด network overhead และให้ UX ดีขึ้นเมื่อดูหลายคันพร้อมกัน

### Problem Statement
**ปัจจุบัน**:
- React Query polling ทุก 10 วินาที (600ms latency × 6 requests/min = 3.6s overhead)
- ดูรถ 50 คัน = 50 HTTP requests ทุก 10 วินาที (bandwidth waste)
- ไม่มี server-initiated push (ต้องรอ poll cycle ถัดไป)

**เป้าหมาย**:
- Sub-second latency สำหรับ position updates
- Broadcast แบบ multicast (1 database query → push หลาย clients)
- Battery-efficient (mobile ไม่ต้อง poll บ่อย)

### Technical Design

#### Architecture
```
Traccar (port 8082)
  ↓ (webhook on position update)
WebSocket Server (port 3002)
  ↓ (Socket.io broadcast)
Frontend Clients (React + Socket.io-client)
```

#### Backend Components

**1. WebSocket Server** (Node.js + Socket.io)
```typescript
// infrastructure/websocket-server/src/index.ts
import { Server } from 'socket.io';
import { createServer } from 'http';
import { traccarWebhook } from './traccarWebhook';
import { authenticateSocket } from './auth';

const httpServer = createServer();
const io = new Server(httpServer, {
  cors: { origin: process.env.FRONTEND_URL },
  transports: ['websocket', 'polling'] // fallback
});

io.use(authenticateSocket); // Verify JSESSIONID cookie

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  // Client subscribes to specific devices
  socket.on('subscribe:devices', (deviceIds: number[]) => {
    deviceIds.forEach(id => socket.join(`device:${id}`));
  });
  
  socket.on('unsubscribe:devices', (deviceIds: number[]) => {
    deviceIds.forEach(id => socket.leave(`device:${id}`));
  });
});

// Traccar webhook endpoint
httpServer.on('request', traccarWebhook(io));

httpServer.listen(3002);
```

**2. Traccar Webhook Handler**
```typescript
// infrastructure/websocket-server/src/traccarWebhook.ts
export function traccarWebhook(io: Server) {
  return (req: IncomingMessage, res: ServerResponse) => {
    if (req.url !== '/webhook/position' || req.method !== 'POST') {
      res.statusCode = 404;
      res.end();
      return;
    }
    
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      const position = JSON.parse(body);
      
      // Broadcast to subscribed clients only
      io.to(`device:${position.deviceId}`).emit('position:update', {
        deviceId: position.deviceId,
        lat: position.latitude,
        lon: position.longitude,
        speed: position.speed,
        course: position.course,
        attributes: position.attributes,
        timestamp: position.fixTime
      });
      
      res.statusCode = 200;
      res.end();
    });
  };
}
```

**3. Traccar Webhook Configuration**
```sql
-- Add webhook notification in Traccar database
INSERT INTO tc_notifications (type, always, attributes)
VALUES ('webhook', true, '{"url":"http://websocket-server:3002/webhook/position"}');

-- Link to all devices (or specific geofence)
INSERT INTO tc_user_notification (userId, notificationId)
SELECT id, LAST_INSERT_ID() FROM tc_users WHERE administrator = true;
```

#### Frontend Integration

**4. Socket.io Client Hook**
```typescript
// src/hooks/useRealtimePositions.ts
import { useEffect, useState } from 'react';
import { io, Socket } from 'socket.io-client';
import { useAuthStore } from '@/stores/authStore';
import type { TraccarPosition } from '@/types/traccar.types';

export function useRealtimePositions(deviceIds: number[]) {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [positions, setPositions] = useState<Map<number, TraccarPosition>>(new Map());
  const { user } = useAuthStore();

  useEffect(() => {
    if (!user) return;

    const ws = io('ws://34.142.244.40:3002', {
      withCredentials: true, // Send JSESSIONID cookie
      transports: ['websocket', 'polling']
    });

    ws.on('connect', () => {
      console.log('WebSocket connected');
      ws.emit('subscribe:devices', deviceIds);
    });

    ws.on('position:update', (data: any) => {
      setPositions(prev => {
        const next = new Map(prev);
        next.set(data.deviceId, data);
        return next;
      });
    });

    ws.on('disconnect', () => {
      console.log('WebSocket disconnected');
    });

    setSocket(ws);

    return () => {
      ws.emit('unsubscribe:devices', deviceIds);
      ws.close();
    };
  }, [deviceIds, user]);

  return { positions: Array.from(positions.values()), connected: socket?.connected };
}
```

**5. Update LiveMapPage**
```typescript
// src/pages/LiveMapPage.tsx (modification)
import { useRealtimePositions } from '@/hooks/useRealtimePositions';
import { useVehicles } from '@/hooks/useVehicles';

export default function LiveMapPage() {
  const { data: vehicles } = useVehicles();
  const deviceIds = vehicles?.map(v => v.id) || [];
  
  // Real-time WebSocket (sub-second updates)
  const { positions: realtimePositions, connected } = useRealtimePositions(deviceIds);
  
  // Fallback polling (every 30s for missed updates)
  const { data: polledPositions } = useQuery({
    queryKey: ['positions'],
    queryFn: () => traccarService.getPositions(),
    refetchInterval: 30_000, // Reduced from 10s
    enabled: !connected // Only poll when WebSocket disconnected
  });

  const positions = connected ? realtimePositions : polledPositions;

  return (
    <div>
      {!connected && <div className="warning">Real-time offline, using fallback</div>}
      <Map positions={positions} />
    </div>
  );
}
```

#### Deployment

**6. Docker Compose Update**
```yaml
# infrastructure/docker/docker-compose.websocket.yml
version: '3.8'
services:
  websocket-server:
    build: ../websocket-server
    container_name: websocket-server
    restart: unless-stopped
    environment:
      - PORT=3002
      - FRONTEND_URL=https://bellerox-gps.pages.dev
      - TRACCAR_URL=http://centerlink-traccar:8082
    ports:
      - "3002:3002"
    networks:
      - centerlink-internal
```

**7. Nginx Proxy Configuration**
```nginx
# infrastructure/docker/nginx/nginx.conf
upstream websocket {
  server websocket-server:3002;
}

server {
  listen 80;
  
  # WebSocket upgrade
  location /socket.io/ {
    proxy_pass http://websocket;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
  }
}
```

### Testing Plan

1. **Unit Tests**: Socket authentication, webhook parsing
2. **Integration Tests**: 
   - Traccar → Webhook → Socket broadcast
   - Client subscribe/unsubscribe
3. **Load Tests**: 100 concurrent clients, 50 vehicles
4. **Battery Tests**: Mobile device power consumption (polling vs WebSocket)

### Success Metrics

- **Latency**: < 500ms from GPS update → UI render
- **Battery**: 30% less drain vs polling (mobile)
- **Scalability**: 200 concurrent users without lag
- **Fallback**: Auto-switch to polling when WebSocket fails

### Estimated Effort

- Backend (WebSocket server): **4 days**
- Frontend (Socket.io integration): **3 days**
- Traccar webhook setup: **1 day**
- Testing + deployment: **2 days**
- **Total**: ~2 weeks

---

## 📱 Phase 8: LINE LIFF Mobile App

### Overview
สร้าง mobile app version ของ Bellerox GPS โดยใช้ LINE LIFF (LINE Front-end Framework) เพื่อเข้าถึง user base ในไทยที่ใช้ LINE อยู่แล้ว — ไม่ต้อง download app ใหม่ เปิดผ่าน LINE ได้เลย

### Why LINE LIFF?

**Market Fit (Thailand)**:
- LINE มี 52M users ในไทย (80% penetration)
- Fleet managers ใช้ LINE กันอยู่แล้ว (communication channel)
- ไม่ต้อง App Store review (deploy instant)
- ไม่ต้องสอนใช้ (เปิดจาก LINE chat เหมือน mini app)

**Technical Benefits**:
- Authentication ผ่าน LINE Login (SSO)
- Push notifications ฟรี (ผ่าน LINE Messaging API)
- Share location, trip reports ผ่าน LINE chat
- Offline mode via Service Worker

### Technical Design

#### Architecture
```
LINE App (iOS/Android)
  ↓ (LIFF SDK)
LIFF Mini App (React SPA)
  ↓ (Same API as web)
API Gateway + Traccar
```

#### Implementation Plan

**1. LINE Developer Console Setup**
```
1. Create LINE Login Channel
   - Channel name: Bellerox GPS
   - Callback URL: https://liff.line.me/redirect
   
2. Create LIFF App
   - Endpoint URL: https://bellerox-gps-liff.pages.dev
   - Size: Full (whole screen)
   - Scope: profile, openid
   - LIFF ID: xxxxx-yyyyyy (จะได้หลัง create)
```

**2. LIFF Frontend (Same codebase, different entry point)**
```typescript
// src/liff/main.tsx
import liff from '@line/liff';
import { createRoot } from 'react-dom/client';
import App from '@/App';

async function initLiff() {
  try {
    await liff.init({ liffId: import.meta.env.VITE_LIFF_ID });
    
    if (!liff.isLoggedIn()) {
      liff.login(); // Redirect to LINE Login
      return;
    }
    
    const profile = await liff.getProfile();
    console.log('LINE User:', profile.displayName);
    
    // Link LINE user to Traccar account (via backend)
    await linkLineAccount(profile.userId);
    
    // Render app
    createRoot(document.getElementById('root')!).render(<App />);
    
  } catch (error) {
    console.error('LIFF init failed:', error);
  }
}

initLiff();
```

**3. LINE Login → Traccar Account Linking**
```typescript
// Backend: infrastructure/api-gateway/src/routes/line-auth.ts
import { Router } from 'express';
import { pool } from '../db';

const router = Router();

router.post('/auth/line/link', async (req, res) => {
  const { lineUserId, traccarEmail, traccarPassword } = req.body;
  
  // 1. Verify Traccar credentials
  const traccarUser = await verifyTraccarLogin(traccarEmail, traccarPassword);
  if (!traccarUser) {
    return res.status(401).json({ error: 'Invalid Traccar credentials' });
  }
  
  // 2. Store LINE ↔ Traccar mapping
  await pool.query(`
    INSERT INTO line_account_links (line_user_id, traccar_user_id, created_at)
    VALUES ($1, $2, NOW())
    ON CONFLICT (line_user_id) DO UPDATE SET traccar_user_id = $2
  `, [lineUserId, traccarUser.id]);
  
  res.json({ success: true, traccarUser });
});

router.get('/auth/line/user/:lineUserId', async (req, res) => {
  const { lineUserId } = req.params;
  
  const result = await pool.query(`
    SELECT t.* FROM tc_users t
    JOIN line_account_links l ON l.traccar_user_id = t.id
    WHERE l.line_user_id = $1
  `, [lineUserId]);
  
  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Account not linked' });
  }
  
  res.json(result.rows[0]);
});

export default router;
```

**4. Database Schema**
```sql
-- Add to PostgreSQL (Traccar database)
CREATE TABLE line_account_links (
  id SERIAL PRIMARY KEY,
  line_user_id VARCHAR(255) UNIQUE NOT NULL,
  traccar_user_id INT NOT NULL REFERENCES tc_users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  last_login TIMESTAMP
);

CREATE INDEX idx_line_user ON line_account_links(line_user_id);
```

**5. LIFF-Specific Features**

**a) Share Trip Report to LINE Chat**
```typescript
// src/liff/features/shareTripReport.ts
import liff from '@line/liff';

export async function shareTripToLineChat(trip: TripReport) {
  const message = {
    type: 'flex',
    altText: `Trip Report: ${trip.vehicleName}`,
    contents: {
      type: 'bubble',
      hero: {
        type: 'image',
        url: generateTripMapImage(trip),
        size: 'full'
      },
      body: {
        type: 'box',
        layout: 'vertical',
        contents: [
          {
            type: 'text',
            text: trip.vehicleName,
            weight: 'bold',
            size: 'xl'
          },
          {
            type: 'text',
            text: `${trip.distance.toFixed(1)} km · ${formatDuration(trip.duration)}`,
            size: 'sm',
            color: '#999999'
          }
        ]
      }
    }
  };
  
  if (liff.isApiAvailable('shareTargetPicker')) {
    await liff.shareTargetPicker([message]);
  }
}
```

**b) Push Notification for Speeding Alert**
```typescript
// Backend: infrastructure/api-gateway/src/services/lineNotify.ts
import axios from 'axios';

export async function sendSpeedingAlert(lineUserId: string, vehicle: string, speed: number) {
  const accessToken = await getLineMessagingToken();
  
  await axios.post('https://api.line.me/v2/bot/message/push', {
    to: lineUserId,
    messages: [
      {
        type: 'text',
        text: `⚠️ แจ้งเตือน: ${vehicle} วิ่งเร็วเกิน ${speed} km/h`
      },
      {
        type: 'text',
        text: 'เปิด Bellerox GPS เพื่อดูรายละเอียด',
        quickReply: {
          items: [
            {
              type: 'action',
              action: {
                type: 'uri',
                label: 'เปิดแอป',
                uri: 'https://liff.line.me/xxxxx-yyyyyy'
              }
            }
          ]
        }
      }
    ]
  }, {
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    }
  });
}
```

**c) Offline Mode with Service Worker**
```typescript
// public/liff-sw.js
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('bellerox-gps-v1').then((cache) => {
      return cache.addAll([
        '/',
        '/index.html',
        '/assets/main.js',
        '/assets/main.css',
        // Cache last known positions
      ]);
    })
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});
```

**6. Build Configuration**
```typescript
// vite.config.liff.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist-liff',
    rollupOptions: {
      input: {
        main: './src/liff/main.tsx'
      }
    }
  },
  define: {
    'process.env.VITE_APP_MODE': JSON.stringify('liff')
  }
});
```

**7. Deployment**
```bash
# Separate Cloudflare Pages project for LIFF
npm run build:liff
npx wrangler pages deploy dist-liff --project-name=bellerox-gps-liff

# Update LINE Developer Console with new LIFF URL
# Endpoint URL: https://bellerox-gps-liff.pages.dev
```

### Mobile-Specific Optimizations

**8. Touch Gestures**
```typescript
// src/liff/components/MobileMap.tsx
import { useSwipeable } from 'react-swipeable';

export function MobileMap() {
  const handlers = useSwipeable({
    onSwipedLeft: () => showNextVehicle(),
    onSwipedRight: () => showPreviousVehicle(),
    onSwipedUp: () => openVehicleDetail(),
    preventScrollOnSwipe: true
  });
  
  return (
    <div {...handlers} className="touch-map">
      <Map />
    </div>
  );
}
```

**9. Battery-Efficient Polling**
```typescript
// src/liff/hooks/useBatteryAwarePolling.ts
export function useBatteryAwarePolling() {
  const [interval, setInterval] = useState(10_000);
  
  useEffect(() => {
    if ('getBattery' in navigator) {
      (navigator as any).getBattery().then((battery: any) => {
        if (battery.level < 0.2) {
          setInterval(30_000); // Slower when low battery
        }
        
        battery.addEventListener('levelchange', () => {
          setInterval(battery.level < 0.2 ? 30_000 : 10_000);
        });
      });
    }
  }, []);
  
  return interval;
}
```

### Testing Plan

1. **LINE LIFF Simulator**: Test on LINE developer tools
2. **Real Device Testing**: iOS (iPhone) + Android
3. **Network Conditions**: Test on 3G/4G/5G + offline mode
4. **Battery Tests**: Measure power consumption over 1 hour
5. **UX Testing**: Thai users (fleet managers) feedback

### Success Metrics

- **Adoption**: 500 MAU within first month
- **Performance**: < 3s initial load on 4G
- **Retention**: 60% D7 (users still active after 7 days)
- **Push Notifications**: 80% open rate for critical alerts

### Estimated Effort

- LINE Developer Console setup: **1 day**
- LIFF SDK integration: **3 days**
- LINE Login → Traccar linking: **2 days**
- Share features (Flex Message): **2 days**
- Push notifications: **2 days**
- Offline mode (Service Worker): **2 days**
- Mobile optimizations: **2 days**
- Testing + deployment: **3 days**
- **Total**: ~3 weeks

---

## 📈 Phase 7-8 Combined Impact

### Performance Improvements
| Metric | Current (Phase 6) | After Phase 7 | After Phase 8 |
|--------|-------------------|---------------|---------------|
| Position update latency | 10s (polling) | **< 0.5s** (WebSocket) | **< 0.5s** |
| Mobile battery drain | Baseline | **-30%** (less polling) | **-50%** (smart polling) |
| User engagement | Web only | Web only | **+LINE** (52M users) |
| Push notification | Email only | Email only | **LINE push** (instant) |

### Cost Impact
- **Phase 7**: +$20/mo (WebSocket server hosting)
- **Phase 8**: +$0/mo (Cloudflare Pages free tier, LINE API free tier)
- **Savings**: -$50/mo (reduced polling = less database load)
- **Net**: **-$30/mo** (cost reduction)

### Technical Debt
- **Phase 7**: None (clean WebSocket architecture)
- **Phase 8**: LINE vendor lock-in (แต่ตลาดไทยไม่มีปัญหา)

---

## 🎯 Recommended Priority

### Must Have (Phase 7)
- Real-time WebSocket → ลด latency 95%, ประสบการณ์ดีขึ้นมาก
- Deployment risk: **Low** (fallback to polling)

### Nice to Have (Phase 8)
- LINE LIFF → เข้าถึง user base ใหญ่, แต่ web app ก็ใช้ได้
- Deployment risk: **Medium** (ต้องทดสอบบน real device)

### Trade-offs
- ถ้า **resource จำกัด**: ทำ Phase 7 ก่อน (impact มากกว่า)
- ถ้า **ต้องการ user growth**: ทำ Phase 8 ก่อน (market reach)
- ถ้า **ทั้งคู่**: Phase 7 → Phase 8 (5 weeks total)

---

## 📋 Prerequisites

### Phase 7 Requirements
- [x] Node.js 18+ (มีอยู่แล้ว)
- [x] Docker + Docker Compose (มีอยู่แล้ว)
- [ ] Socket.io server knowledge (ต้องศึกษา)
- [ ] Traccar webhook configuration access

### Phase 8 Requirements
- [x] React + TypeScript (มีอยู่แล้ว)
- [ ] LINE Developer Account (สมัครฟรี)
- [ ] LINE OA (Official Account) for push notifications
- [ ] Mobile testing devices (iOS + Android)
- [ ] LIFF SDK knowledge (ต้องศึกษา)

---

## 🎓 Learning Resources

### Phase 7: WebSocket
- Socket.io Documentation: https://socket.io/docs/v4/
- Traccar Webhooks: https://www.traccar.org/notifications/
- WebSocket Security: OWASP WebSocket Security Guide

### Phase 8: LINE LIFF
- LIFF Documentation: https://developers.line.biz/en/docs/liff/
- LINE Messaging API: https://developers.line.biz/en/docs/messaging-api/
- LIFF Playground: https://liff-playground.netlify.app/

---

## 🧪 Phase 9: Automated Testing (RECOMMENDED)

### Overview
เพิ่ม automated test suite เพื่อป้องกัน regression bugs เมื่อเพิ่ม Phase 7-8 — ตอนนี้ test แบบ manual อย่างเดียว ซึ่ง fragile และช้า

### Problem Statement
**ปัจจุบัน** (จาก assessment.md):
- Testing score: **85/100**
- ❌ No unit tests (0 test files)
- ❌ No integration tests (API Gateway → PostgreSQL)
- ❌ No E2E tests (Playwright/Cypress)
- ❌ No load tests (k6/Artillery)
- ⚠️ Manual testing only (regression risk สูง)

**เป้าหมาย**:
- Testing score: **95/100**
- Unit tests for hooks, services, utils
- Integration tests for API endpoints
- E2E tests for critical paths
- Load tests for 100+ concurrent users

### Technical Design

#### 1. Unit Tests (Vitest)
```typescript
// src/hooks/__tests__/useActivityTimeline.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useActivityTimeline } from '../useActivityTimeline';

test('loads activity timeline for device 42', async () => {
  const queryClient = new QueryClient();
  const wrapper = ({ children }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
  
  const { result } = renderHook(() => 
    useActivityTimeline('42', [new Date('2026-08-22'), new Date('2026-08-22')]),
    { wrapper }
  );
  
  await waitFor(() => expect(result.current.isLoading).toBe(false));
  expect(result.current.data.length).toBeGreaterThan(0);
  expect(result.current.data[0]).toHaveProperty('segment_type');
});

// src/lib/__tests__/units.test.ts
import { knotsToKmh, formatDuration, formatDistance } from '../units';

test('knotsToKmh converts correctly', () => {
  expect(knotsToKmh(10)).toBeCloseTo(18.52, 1);
  expect(knotsToKmh(0)).toBe(0);
});

test('formatDuration handles Thai text', () => {
  expect(formatDuration(3665)).toBe('1 ชม. 1 นาที');
  expect(formatDuration(60)).toBe('1 นาที');
});
```

#### 2. Integration Tests (Supertest)
```typescript
// infrastructure/api-gateway/src/__tests__/activity.test.ts
import request from 'supertest';
import app from '../server';

describe('GET /api/reports/activity', () => {
  test('returns 401 without auth', async () => {
    const res = await request(app)
      .get('/api/reports/activity?deviceId=42&date=2026-08-22');
    expect(res.status).toBe(401);
  });
  
  test('returns activities with valid auth', async () => {
    const res = await request(app)
      .get('/api/reports/activity?deviceId=42&date=2026-08-22')
      .set('Cookie', 'JSESSIONID=test-session');
    
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toHaveProperty('segment_type');
  });
});
```

#### 3. E2E Tests (Playwright)
```typescript
// e2e/login-to-map.spec.ts
import { test, expect } from '@playwright/test';

test('login → view map → vehicles appear', async ({ page }) => {
  // 1. Navigate to login page
  await page.goto('http://localhost:5173');
  
  // 2. Fill credentials
  await page.fill('input[name="email"]', 'admin@bellerox.com');
  await page.fill('input[name="password"]', process.env.TEST_PASSWORD);
  await page.click('button[type="submit"]');
  
  // 3. Wait for map page
  await expect(page).toHaveURL(/.*\/app\/map/);
  
  // 4. Verify vehicle markers appear
  const markers = page.locator('.leaflet-marker-icon');
  await expect(markers).toHaveCount({ min: 1, max: 200 });
  
  // 5. Click a marker → vehicle detail appears
  await markers.first().click();
  await expect(page.locator('[data-testid="vehicle-detail"]')).toBeVisible();
});
```

#### 4. Load Tests (k6)
```javascript
// load-tests/websocket-stress.js
import ws from 'k6/ws';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 50 },   // Ramp up to 50 users
    { duration: '3m', target: 100 },  // Ramp up to 100 users
    { duration: '2m', target: 0 },    // Ramp down
  ],
};

export default function () {
  const url = 'wss://traccar.gps.bellerox.com/socket.io/';
  const params = { headers: { Cookie: 'JSESSIONID=...' } };
  
  const res = ws.connect(url, params, function (socket) {
    socket.on('open', () => {
      socket.send(JSON.stringify({ type: 'subscribe', devices: [1,2,3] }));
    });
    
    socket.on('message', (data) => {
      check(data, { 'received position update': (d) => d !== '' });
    });
    
    socket.setTimeout(() => socket.close(), 60000); // 1 min per user
  });
  
  check(res, { 'WebSocket connected': (r) => r && r.status === 101 });
}
```

### Implementation Steps

**Step 1: Setup Vitest (Unit Tests)**
- [ ] Install: `vitest @testing-library/react @testing-library/react-hooks`
- [ ] Create `vitest.config.ts`
- [ ] Add `npm test` script
- [ ] Write tests for: `units.ts`, `useDevices.ts`, `useActivityTimeline.ts`

**Step 2: Setup Supertest (Integration Tests)**
- [ ] Install: `supertest @types/supertest`
- [ ] Create test database (separate from production)
- [ ] Write tests for: `/api/reports/activity`, `/health`

**Step 3: Setup Playwright (E2E Tests)**
- [ ] Install: `@playwright/test`
- [ ] Create `playwright.config.ts`
- [ ] Write tests for: login flow, map display, vehicle detail

**Step 4: Setup k6 (Load Tests)**
- [ ] Install k6: `brew install k6` (macOS) or docker
- [ ] Write load test scripts
- [ ] Run baseline tests (record results)

**Step 5: CI/CD Integration**
- [ ] Add GitHub Actions workflow (`.github/workflows/test.yml`)
- [ ] Run tests on every PR
- [ ] Block merge if tests fail

### Success Criteria

- ✅ Unit tests: 80%+ code coverage for critical paths
- ✅ Integration tests: All API endpoints covered
- ✅ E2E tests: 5+ critical user flows working
- ✅ Load tests: Handle 100+ concurrent users
- ✅ CI/CD: Tests run automatically on PR
- ✅ Build passes with zero TypeScript errors

### Estimated Effort

- Vitest setup + unit tests: **3 days**
- Supertest integration tests: **2 days**
- Playwright E2E tests: **3 days**
- k6 load tests: **1 day**
- CI/CD integration: **1 day**
- **Total**: ~2 weeks

---

## 🔒 Phase 10: Production Hardening (RECOMMENDED)

### Overview
แก้ช่องโหว่ที่เหลือจาก assessment.md เพื่อให้ระบบพร้อม production จริงๆ — ตอนนี้ยังขาด HTTPS, audit logs, API docs

### Problem Statement
**ปัจจุบัน** (จาก assessment.md):
- Security score: **88/100**
- ❌ No HTTPS (HTTP only, credentials sent in plaintext)
- ❌ No audit logging (GDPR/compliance gap)
- ❌ No API documentation (Swagger/OpenAPI)
- ❌ No rate limiting on API Gateway (only nginx)

**เป้าหมาย**:
- Security score: **95/100**
- HTTPS with Let's Encrypt
- Audit logs (who accessed what device)
- Swagger UI for API documentation
- Express rate limiting middleware

### Technical Design

#### 1. HTTPS with Let's Encrypt
```bash
# infrastructure/scripts/setup-ssl.sh
#!/bin/bash

# Install certbot
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

# Request certificate
sudo certbot --nginx \
  -d traccar.gps.bellerox.com \
  --email admin@bellerox.com \
  --agree-tos \
  --non-interactive

# Auto-renewal (cron)
sudo crontab -l | { cat; echo "0 0 * * * certbot renew --quiet"; } | sudo crontab -
```

**nginx.conf changes:**
```nginx
server {
  listen 443 ssl http2;
  server_name traccar.gps.bellerox.com;
  
  ssl_certificate /etc/letsencrypt/live/traccar.gps.bellerox.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/traccar.gps.bellerox.com/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5;
  
  # ... rest of config
}

server {
  listen 80;
  server_name traccar.gps.bellerox.com;
  return 301 https://$host$request_uri; # Redirect HTTP → HTTPS
}
```

#### 2. Audit Logging
```sql
-- Create audit_logs table
CREATE TABLE audit_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES tc_users(id),
  action VARCHAR(50) NOT NULL, -- 'view_device', 'view_report', 'export_data'
  resource_type VARCHAR(50), -- 'device', 'report', 'geofence'
  resource_id INTEGER,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_time ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
```

**Express middleware:**
```typescript
// infrastructure/api-gateway/src/middleware/auditLog.ts
import { pool } from '../db';

export async function auditLog(req, res, next) {
  const userId = req.session?.userId;
  const action = `${req.method} ${req.path}`;
  const ipAddress = req.ip;
  const userAgent = req.headers['user-agent'];
  
  // Parse resource from path (e.g. /api/reports/activity?deviceId=42)
  const deviceId = req.query.deviceId || req.params.deviceId;
  
  await pool.query(
    'INSERT INTO audit_logs (user_id, action, resource_type, resource_id, ip_address, user_agent) VALUES ($1, $2, $3, $4, $5, $6)',
    [userId, action, 'device', deviceId, ipAddress, userAgent]
  );
  
  next();
}
```

#### 3. Swagger API Documentation
```typescript
// infrastructure/api-gateway/src/swagger.ts
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Bellerox GPS API',
      version: '1.0.0',
      description: 'Custom aggregation endpoints for GPS fleet management',
    },
    servers: [
      { url: 'https://traccar.gps.bellerox.com', description: 'Production' },
      { url: 'http://localhost:3001', description: 'Development' },
    ],
  },
  apis: ['./src/routes/*.ts'],
};

const specs = swaggerJsdoc(options);

export function setupSwagger(app) {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
}
```

**Route documentation:**
```typescript
/**
 * @swagger
 * /api/reports/activity:
 *   get:
 *     summary: Get 24-hour activity timeline
 *     parameters:
 *       - in: query
 *         name: deviceId
 *         schema:
 *           type: integer
 *         required: true
 *       - in: query
 *         name: date
 *         schema:
 *           type: string
 *           format: date
 *         required: true
 *     responses:
 *       200:
 *         description: Activity segments
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   segment_type:
 *                     type: string
 *                     enum: [trip, idle, stopped]
 *                   start_time:
 *                     type: string
 *                   duration_seconds:
 *                     type: integer
 */
router.get('/api/reports/activity', activityController);
```

#### 4. Express Rate Limiting
```typescript
// infrastructure/api-gateway/src/middleware/rateLimit.ts
import rateLimit from 'express-rate-limit';

export const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // 100 requests per minute per IP
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

export const reportLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10, // 10 reports per minute per IP
  message: 'Report rate limit exceeded.',
});
```

**Apply to routes:**
```typescript
import { apiLimiter, reportLimiter } from './middleware/rateLimit';

app.use('/api/', apiLimiter);
app.use('/api/reports/', reportLimiter);
```

### Implementation Steps

**Step 1: HTTPS Setup**
- [ ] Run setup-ssl.sh script on production VM
- [ ] Verify certificate renewal cron job
- [ ] Update nginx.conf with SSL config
- [ ] Test HTTPS connection

**Step 2: Audit Logging**
- [ ] Create audit_logs table in PostgreSQL
- [ ] Implement audit middleware
- [ ] Add to API Gateway routes
- [ ] Create admin page to view logs

**Step 3: API Documentation**
- [ ] Install swagger-jsdoc + swagger-ui-express
- [ ] Add JSDoc comments to routes
- [ ] Serve at /api-docs
- [ ] Test Swagger UI

**Step 4: Rate Limiting**
- [ ] Install express-rate-limit
- [ ] Apply to routes
- [ ] Test rate limit enforcement

### Success Criteria

- ✅ HTTPS: SSL certificate valid, auto-renews
- ✅ HTTP → HTTPS redirect works
- ✅ Audit logs: All API calls logged
- ✅ Swagger UI: Accessible at /api-docs
- ✅ Rate limiting: Blocks excessive requests
- ✅ Security score: 95/100 (from 88/100)

### Estimated Effort

- HTTPS setup: **0.5 day**
- Audit logging: **2 days**
- Swagger documentation: **1 day**
- Rate limiting: **0.5 day**
- Testing + verification: **1 day**
- **Total**: ~1 week

---

## 📊 Phase 7-10 Combined Roadmap

### Timeline Overview
```
Phase 7 (WebSocket):        ████████████████ (2 weeks)
Phase 8 (LINE LIFF):                        ████████████████████ (3 weeks)
Phase 9 (Testing):          ████████████████ (2 weeks, can run in parallel)
Phase 10 (Hardening):       ████████ (1 week, can run in parallel)
                            ├─────────┼─────────┼─────────┼─────────┤
                            Week 1-2  Week 3-4  Week 5-6  Week 7-8
```

**Parallel execution**:
- Phase 7 + Phase 9 (weeks 1-2): WebSocket dev + unit tests
- Phase 8 + Phase 10 (weeks 3-5): LINE LIFF dev + production hardening
- **Total**: 6-8 weeks for all phases

### Priority Ranking

| Phase | Impact | Effort | Priority | Start After |
|-------|--------|--------|----------|-------------|
| **Phase 7** (WebSocket) | 🔥🔥🔥🔥🔥 Very High | 2 weeks | ⭐⭐⭐⭐⭐ Must Have | Now |
| **Phase 9** (Testing) | 🔥🔥🔥🔥 High | 2 weeks | ⭐⭐⭐⭐ Must Have | With Phase 7 |
| **Phase 10** (Hardening) | 🔥🔥🔥🔥 High | 1 week | ⭐⭐⭐⭐ Must Have | Before production |
| **Phase 8** (LINE LIFF) | 🔥🔥🔥 Medium | 3 weeks | ⭐⭐⭐ Nice to Have | After Phase 7 |

### Score Projection

| After Phase | Code | Perf | Arch | Security | Docs | Testing | **Overall** |
|-------------|------|------|------|----------|------|---------|-------------|
| **Phase 6** (Current) | 95 | 98 | 90 | 88 | 94 | 85 | **92/100** ⭐⭐⭐⭐ |
| **Phase 7** (WebSocket) | 95 | 100 | 92 | 88 | 95 | 85 | **93/100** |
| **Phase 9** (Testing) | 96 | 100 | 92 | 88 | 95 | 95 | **95/100** ⭐⭐⭐⭐⭐ |
| **Phase 10** (Hardening) | 96 | 100 | 92 | 95 | 96 | 95 | **96/100** ⭐⭐⭐⭐⭐ |
| **Phase 8** (LINE LIFF) | 96 | 100 | 93 | 95 | 96 | 95 | **96/100** |

**Target**: 96/100 (World-class quality) after all phases complete

---

## 🎯 Recommended Execution Plan

### Option A: Quality First (Recommended)
```
1. Phase 7 (WebSocket) — 2 weeks
2. Phase 9 (Testing) — 2 weeks (parallel with Phase 7 end)
3. Phase 10 (Hardening) — 1 week
4. Phase 8 (LINE LIFF) — 3 weeks (optional)
Total: 5-8 weeks
```

**Why**: Ensures production quality before adding mobile features

### Option B: Market First
```
1. Phase 7 (WebSocket) — 2 weeks
2. Phase 8 (LINE LIFF) — 3 weeks
3. Phase 9 + 10 (Quality) — 3 weeks
Total: 8 weeks
```

**Why**: Faster time-to-market for LINE users (52M potential users)

### Option C: Minimal (Production-Ready Only)
```
1. Phase 7 (WebSocket) — 2 weeks
2. Phase 9 (Testing) — 2 weeks
3. Phase 10 (Hardening) — 1 week
Skip Phase 8
Total: 5 weeks
```

**Why**: Production-grade without mobile app (web is enough for now)

---

**Status**: 
- Phase 7: 🔄 IN PROGRESS (1/8 tasks complete)
- Phase 8-10: 📋 PLANNING COMPLETE  

**Next Action**: Continue Phase 7 Task 2 (WebSocket Server Setup)  
**Estimated Total**: 5-8 weeks (all phases) or 2 weeks (Phase 7 only)

---

*แผนครบทั้ง 4 phase แล้ว — พร้อมทำต่อได้เลย!* 🚀
