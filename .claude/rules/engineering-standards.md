# Engineering Standards — Bellerox GPS
# World-class GPS application engineering discipline

## Architecture Rules

### 1. Service Layer Pattern (strict)
```
Page/Component → React Query Hook → Service Function → traccarClient → Traccar API
```
- Pages NEVER call traccarClient directly
- Hooks NEVER call Traccar API directly
- Services throw on error (let React Query + toast handle display)

### 2. Real-time Strategy
- WebSocket connection: `/api/socket` (Traccar built-in)
- Use React Query + manual invalidation on WebSocket messages
- Fallback: polling every 10s if WebSocket disconnects
- Never poll faster than 5s (Traccar default rate limit)

### 3. Type Safety
- `traccar.types.ts` is source of truth for API types
- Derive extended types from Traccar types (extend, don't duplicate)
- `VehicleWithPosition` extends `TraccarDevice` — this pattern
- Speed always stored as **knots** internally, displayed as **km/h** via `knotsToKmh()`

### 4. State Management
- **React Query**: all GPS data (positions, devices, events, reports)
- **Zustand**: auth only (`authStore.ts`) + UI ephemeral state (selected vehicle, map zoom)
- Never cache API data in component state — React Query does it
- Never put GPS positions in Zustand — they update every 10s, React Query handles it

### 5. Map Rules
- One `MapContainer` per page — never mount multiple Leaflet maps
- Vehicle icons created by `createVehicleIcon()` — never inline HTML strings elsewhere
- Leaflet `L.divIcon` for custom markers (DivIcon is faster than ImageIcon for many markers)
- At > 500 markers, use marker clustering (`leaflet.markercluster`)
- At > 2000 markers, use canvas rendering (`leaflet-canvas-markers`)

## Performance Rules

### Map Performance (critical for fleet managers watching 4000 vehicles)
- **< 100 vehicles**: Regular Leaflet markers
- **100-500 vehicles**: Marker clustering (`react-leaflet-cluster`)
- **500-2000 vehicles**: Canvas markers
- **> 2000 vehicles**: Server-side clustering + viewport-based filtering

### Viewport Filtering
Only render markers within current map bounds + 20% buffer:
```typescript
const visibleVehicles = vehicles.filter(v => {
  if (!v.position) return false;
  const bounds = mapRef.current?.getBounds().pad(0.2);
  return bounds?.contains([v.position.latitude, v.position.longitude]);
});
```

### React Query Config for GPS
```typescript
// Positions: 10s refetch, 5s stale (real-time feel)
positions: { refetchInterval: 10_000, staleTime: 5_000 }
// Devices: 30s refetch, 20s stale (changes less often)
devices: { refetchInterval: 30_000, staleTime: 20_000 }
// Reports: No refetch (historical data), 5 min stale
reports: { refetchInterval: false, staleTime: 5 * 60_000 }
// Events: 30s refetch
events: { refetchInterval: 30_000 }
```

## WebSocket Integration

### Traccar WebSocket Protocol
```typescript
// Connect to Traccar WebSocket
const ws = new WebSocket(`wss://api.gps.bellerox.com/api/socket`);

// Messages are JSON objects:
// Position update:
{ positions: [{ id, deviceId, latitude, longitude, speed, ... }] }
// Device status update:
{ devices: [{ id, status, lastUpdate, positionId, ... }] }
// Event:
{ events: [{ id, deviceId, type, eventTime, ... }] }
```

### React Integration Pattern
```typescript
// In useTraccarWebSocket.ts hook:
useEffect(() => {
  const ws = new WebSocket(WS_URL);
  ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.positions) queryClient.setQueryData(['positions', 'current'], 
      (old) => mergePositions(old, data.positions));
    if (data.devices) queryClient.invalidateQueries({ queryKey: ['devices'] });
    if (data.events) queryClient.invalidateQueries({ queryKey: ['events'] });
  };
  ws.onclose = () => { /* reconnect with backoff */ };
  return () => ws.close();
}, [queryClient]);
```

## Code Standards

### TypeScript
- Strict mode always on
- No `any` — use `unknown` at boundaries, then narrow
- GPS coordinates: `number` (not string) always
- Timestamps from Traccar: ISO string → convert to `Date` at display layer only

### Naming
- `deviceId` → Traccar's internal ID (number)
- `uniqueId` → IMEI or device identifier (string)
- `vehicleId` → Business concept (could differ from deviceId)
- `position` → Current GPS position (TraccarPosition)
- `track` → Array of positions (route history)

### File Naming
```
src/
  services/traccarService.ts       # Traccar API
  services/geocodingService.ts     # Address lookup
  services/alertService.ts         # Alert rules management
  hooks/useDevices.ts              # Devices React Query
  hooks/usePositions.ts            # Positions + WebSocket
  hooks/useReports.ts              # Trip/summary reports
  hooks/useGeofences.ts            # Geofence CRUD
  hooks/useTraccarWebSocket.ts     # WS real-time connection
  components/map/VehicleMap.tsx    # Reusable map component
  components/map/VehicleMarker.tsx # Single vehicle marker
  components/map/GeofenceLayer.tsx # Geofence overlays
  components/fleet/VehicleList.tsx # Fleet sidebar list
  pages/LiveMapPage.tsx            # Route: /app/map
  pages/FleetPage.tsx              # Route: /app/fleet
```

## Security Rules

### Auth
- Basic auth headers sent via Axios interceptor (never in URL)
- Credentials stored in Zustand `persist` (localStorage encrypted in prod)
- Session check on app mount via `GET /api/session`
- Auto-logout on 401 response

### GPS Data Privacy (PDPA Thailand)
- Driver position = personal data under Thai PDPA
- Never log raw positions to console in production
- Driver opt-in required (show consent banner on first mobile app launch)
- Admin cannot track employee's personal phone (only company-assigned devices)

### Network
- All API calls via Cloudflare Worker proxy (hides Traccar server address)
- Traccar API port 8082 NOT directly accessible from internet (only via Nginx/Worker)
- GPS device ports (5000-5170) open on server but no HTTP — protocol level only

## Testing Standards

### What to Test
- Unit test: `knotsToKmh()`, `formatDistance()`, `formatDuration()` — pure functions
- Unit test: Vehicle state calculation (`displayStatus` logic)
- Unit test: Trip detection algorithm
- Integration test: Traccar service functions (mock traccarClient)
- E2E: Login → see map → vehicles appear (critical path)

### Test Location
```
src/
  lib/__tests__/units.test.ts
  lib/__tests__/vehicleState.test.ts
  services/__tests__/traccarService.test.ts
```

## Definition of Done

A feature is done when:
- TypeScript compiles with zero errors (`npm run build`)
- ESLint passes with zero warnings
- Map loads and shows vehicle markers
- Loading states handled (spinner while fetching)
- Empty state handled (EmptyState component when no vehicles)
- Error state handled (toast + retry button)
- Mobile responsive (works on 375px width)
- Thai text displays correctly (Sarabun font)
