# Phase 7: Real-time WebSocket Implementation

**Status**: 🔄 In Progress  
**Started**: 2026-08-24  
**Target**: Complete within 2 weeks

---

## 🎯 Goal

Implement real-time position updates via WebSocket to reduce latency from **10 seconds to < 1 second**.

**Current State**: Polling-based (positions every 10s, devices every 30s)  
**Target State**: WebSocket-first with polling fallback

---

## 📋 Task Breakdown

### ✅ Task 1: Fix UI Bugs (DONE)
- [x] Fix missing "ตำแหน่งล่าสุด" (address) for stopped vehicles
- [x] Fix missing "อัพเดตล่าสุด" (lastSeen time) display
- [x] Solution: 
  - `useDevices.ts`: Ensure `lastSeen` fallback chain (effectiveTime → device.lastUpdate → now)
  - `FleetPage.tsx`: Show lat/lng if address is missing
- [x] **Files changed**: 
  - `bellerox-gps-web/src/hooks/useDevices.ts`
  - `bellerox-gps-web/src/pages/FleetPage.tsx`

---

### 🔄 Task 2: WebSocket Server Setup

**Files to create:**
```
infrastructure/websocket-server/
├── package.json
├── tsconfig.json
├── src/
│   ├── server.ts           # Express + Socket.io server
│   ├── auth.ts             # Traccar session verification
│   ├── rooms.ts            # Room management (device:123, fleet)
│   └── types.ts            # TypeScript types
├── Dockerfile
└── .dockerignore
```

**Dependencies:**
- `socket.io` (WebSocket server)
- `express` (HTTP server for health checks)
- `axios` (verify Traccar session)
- `dotenv` (env config)

**Implementation steps:**
- [ ] Create directory structure
- [ ] Install dependencies
- [ ] Create `server.ts` with Socket.io + Express
- [ ] Implement authentication middleware (verify JSESSIONID cookie)
- [ ] Add room-based subscriptions (client subscribes to device IDs)
- [ ] Create Dockerfile
- [ ] Add to docker-compose.yml

**Success criteria:**
- Server starts successfully on port 3002
- Client can connect with valid Traccar session
- Client can subscribe to device rooms
- Health check endpoint `/health` returns 200

---

### 🔄 Task 3: Traccar Webhook Integration

**Traccar webhook config:**
```xml
<!-- traccar.xml -->
<entry key='notificator.types'>web</entry>
<entry key='notificator.web.url'>http://websocket-server:3002/webhook/traccar</entry>
```

**Webhook endpoint:**
```typescript
// POST /webhook/traccar
// Receives: { positions: [...], devices: [...], events: [...] }
// Broadcasts to subscribed clients in real-time
```

**Implementation steps:**
- [ ] Create `/webhook/traccar` endpoint
- [ ] Parse Traccar webhook payload
- [ ] Broadcast position updates to subscribed rooms
- [ ] Broadcast device status updates
- [ ] Broadcast events (alerts)
- [ ] Add error handling + logging
- [ ] Add retry logic for failed broadcasts

**Success criteria:**
- Webhook receives Traccar updates
- Updates broadcast to correct rooms
- < 100ms latency from Traccar to client
- Failed broadcasts logged

---

### 🔄 Task 4: Frontend WebSocket Client

**Files to create/modify:**
```
bellerox-gps-web/src/
├── services/websocketService.ts    # Socket.io client wrapper
├── hooks/useWebSocket.ts           # React hook for WebSocket
└── stores/realtimeStore.ts         # Update with WS status
```

**Implementation steps:**
- [ ] Create `websocketService.ts` (Socket.io client)
- [ ] Implement auto-reconnect with exponential backoff
- [ ] Create `useWebSocket.ts` React hook
- [ ] Subscribe to device rooms on mount
- [ ] Integrate with React Query (manual cache updates)
- [ ] Add connection status indicator to UI
- [ ] Fallback to polling when WebSocket disconnects
- [ ] Update `useVehiclesWithPositions` to use WS updates

**Auto-reconnect strategy:**
```typescript
// Exponential backoff: 1s → 2s → 4s → 8s → 16s (max)
// Max retries: 5
// After max retries: fallback to polling
```

**Success criteria:**
- Client connects to WebSocket server
- Position updates appear in < 1 second
- Auto-reconnect works after network failure
- Polling resumes when WebSocket unavailable
- Connection status visible in UI

---

### 🔄 Task 5: Nginx Reverse Proxy

**nginx.conf changes:**
```nginx
# WebSocket upgrade path
location /socket.io/ {
    proxy_pass http://websocket-server:3002;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;
}
```

**Implementation steps:**
- [ ] Add WebSocket location block to nginx.conf
- [ ] Configure proxy headers for WebSocket upgrade
- [ ] Set long timeouts (no idle timeout)
- [ ] Test SSL/TLS compatibility
- [ ] Add rate limiting (max connections per IP)

**Success criteria:**
- WebSocket connection works through nginx
- SSL/TLS termination works
- No disconnections from idle timeout

---

### 🔄 Task 6: Docker Compose Integration

**docker-compose.yml changes:**
```yaml
services:
  websocket-server:
    build: ./infrastructure/websocket-server
    container_name: bellerox-websocket
    restart: unless-stopped
    ports:
      - "3002:3002"
    environment:
      - NODE_ENV=production
      - TRACCAR_API_URL=http://traccar:8082
      - PORT=3002
    networks:
      - bellerox-network
    depends_on:
      - traccar
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3002/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

**Implementation steps:**
- [ ] Add websocket-server service to docker-compose.yml
- [ ] Configure environment variables
- [ ] Add health check
- [ ] Test deployment

**Success criteria:**
- Container starts successfully
- Health check passes
- Connects to Traccar API
- Receives webhook events

---

### 🔄 Task 7: Testing & Verification

**Test cases:**
1. **Real-time updates**: Position appears in < 1 second
2. **Reconnection**: Network failure → auto-reconnect works
3. **Fallback**: WebSocket unavailable → polling resumes
4. **Load test**: 100+ concurrent connections work
5. **Multi-tab**: Multiple browser tabs work correctly
6. **Build**: `npm run build` passes with zero errors

**Implementation steps:**
- [ ] Manual testing on dev environment
- [ ] Test reconnection scenarios
- [ ] Test fallback to polling
- [ ] Load test with multiple clients
- [ ] Test multi-tab behavior
- [ ] Verify build passes

**Success criteria:**
- All test cases pass
- Zero TypeScript errors
- Zero ESLint errors
- Load test handles 100+ connections

---

### 🔄 Task 8: Documentation

**Files to update:**
- [ ] `DEPLOYMENT.md` — Add WebSocket architecture diagram
- [ ] `DEPLOYMENT.md` — Add WebSocket troubleshooting section
- [ ] `infrastructure/docker/nginx/nginx.conf` — Add WebSocket comments
- [ ] `.toh/assessment.md` — Update score after Phase 7

**Content to add:**
- Architecture diagram showing Traccar → WebSocket server → clients
- Deployment checklist for WebSocket server
- Troubleshooting: connection issues, firewall, SSL
- Performance benchmarks (latency measurements)

---

## 📊 Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1. Fix UI bugs | ✅ DONE | lastSeen fallback + address lat/lng |
| 2. WebSocket server | ⏳ TODO | Socket.io + Express + auth |
| 3. Traccar webhook | ⏳ TODO | Broadcast to rooms |
| 4. Frontend client | ⏳ TODO | Auto-reconnect + React Query |
| 5. Nginx proxy | ⏳ TODO | WebSocket upgrade |
| 6. Docker compose | ⏳ TODO | Add service |
| 7. Testing | ⏳ TODO | Load test 100+ connections |
| 8. Documentation | ⏳ TODO | DEPLOYMENT.md update |

**Overall progress**: 1/8 tasks complete (12.5%)

---

## 🎯 Success Criteria

**Must have:**
- ✅ Position updates < 1 second latency (down from 10s)
- ✅ Auto-reconnect with exponential backoff
- ✅ Fallback to polling when WebSocket unavailable
- ✅ Zero TypeScript errors
- ✅ Build passes
- ✅ All Docker containers healthy

**Nice to have:**
- Battery-efficient (reduced polling = 30% battery savings)
- Connection status indicator in UI
- WebSocket metrics in monitoring

---

## 🚀 Next Steps

**Immediate**: Start Task 2 — Create WebSocket server structure  
**Timeline**: Complete all tasks within 2 weeks  
**Blockers**: None currently

---

**Last updated**: 2026-08-24
