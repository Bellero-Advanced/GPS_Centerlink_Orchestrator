# Mobile App: Multi-Tenant White-Label + Complete Features
# iOS + Android | React Native + Expo
# Date: 2026-08-25

---

## Goal

Build **white-label multi-tenant mobile app** (iOS + Android) where:
- **Each tenant gets their own branded app** (different app icon, colors, name)
- **Full feature parity** with web live map
- **Single codebase** builds multiple apps via configuration
- Real-time tracking, offline mode, push notifications, background tracking

**Architecture:** 
- Base app code → Build variants for each tenant
- Tenant config (brand, API endpoint, colors) → Separate app bundles
- Each tenant submits to App Store/Play Store independently

---

## Stack

**Framework:** React Native 0.81.5 + Expo 54  
**Multi-Tenant:** EAS Build + app.config.js dynamic variants  
**Navigation:** Expo Router 6.0  
**State:** Zustand 4.5  
**Data:** React Query 5.50 + AsyncStorage  
**Maps:** React Native Maps 1.20  
**Notifications:** Expo Notifications 0.32  
**Location:** Expo Location 19.0  
**Storage:** Expo SecureStore 15.0 + AsyncStorage 3.1  
**i18n:** i18next 26.3 (Thai + English)

**Existing base:** `bellerox-gps-mobile/` (Expo app initialized)

---

## Pages (Screens)

**Bottom Tabs:**
1. **Map** - Live vehicle tracking (main screen)
2. **Vehicles** - Vehicle list with search/filter
3. **Alerts** - Notification center
4. **Reports** - Analytics & trip reports
5. **Profile** - Settings & account

**Modal Screens:**
- Vehicle Detail (full info + trip history)
- Trip Replay (playback)
- Geofence Management
- Driver Management
- Settings (notifications, offline, language)

---

## Done When

- [ ] Multi-tenant architecture working (1 codebase → N apps)
- [ ] All web live map features work on mobile
- [ ] Real-time WebSocket updates working
- [ ] Offline mode: stores last 7 days positions
- [ ] Push notifications for alerts
- [ ] Background tracking (driver mode)
- [ ] Build passes for 2 test tenants: `eas build --profile tenant1` + `tenant2`
- [ ] Tested on iOS Simulator + Android Emulator
- [ ] Documentation for onboarding new tenants

---

## Phases

### Phase 0: Multi-Tenant Architecture Setup

**T0.1** `dev-builder` — Tenant configuration system  
File: `config/tenants.json`, `config/tenantConfig.ts`  
- JSON config per tenant: `{ id, name, bundleId, colors, logo, apiUrl }`
- Dynamic loading based on build variant

**T0.2** `platform-adapter` — EAS Build profiles per tenant  
File: `eas.json`, `app.config.js`  
- Build profiles: `tenant1-prod`, `tenant2-prod`, etc.
- Dynamic app.json generation per tenant
- Bundle IDs: `com.bellerox.gps.tenant1`, `com.bellerox.gps.tenant2`

**T0.3** `dev-builder` — Tenant theme system  
File: `src/theme/tenantTheme.ts`, `src/theme/ThemeProvider.tsx`  
- Load colors from tenant config
- Apply to all components
- Custom logo/splash per tenant

**T0.4** `dev-builder` — Tenant API client  
File: `src/services/api.ts`  
- API base URL from tenant config
- Multi-tenant auth (tenantId in headers)
- Tenant-specific storage keys

**Checkpoint:** Can build 2 different branded apps from same codebase

---

### Phase 1: Core Map & Real-time Tracking (Foundation)

**T1.1** `dev-builder` — Setup API client with WebSocket support  
File: `src/services/api.ts`, `src/services/websocket.ts`  
- Axios client with auth interceptor
- WebSocket manager for real-time positions
- Reconnect logic (exponential backoff)
- Tenant-scoped API endpoints

**T1.2** [P] `ui-builder` — Map screen with vehicle markers  
File: `app/(tabs)/map.tsx`, `src/components/map/VehicleMarker.tsx`  
- React Native Maps with custom markers
- Vehicle status colors (online=green, offline=grey, idle=yellow)
- Cluster markers for many vehicles
- Follow mode (center on selected vehicle)
- Tenant brand colors for markers

**T1.3** [P] `dev-builder` — Vehicle state management  
File: `src/stores/vehicleStore.ts`  
- Zustand store for vehicles + positions
- Real-time updates from WebSocket
- Filter by status/group
- Tenant-scoped data

**T1.4** `ui-builder` — Vehicle info bottom sheet  
File: `src/components/map/VehicleBottomSheet.tsx`  
- Slide-up sheet on marker tap
- Speed, location, status, battery
- "View Details" button → Vehicle Detail screen
- Tenant brand styling

**Checkpoint:** Map shows vehicles in real-time, works for multiple tenants

---

### Phase 2: Vehicle Management & Details

**T2.1** `ui-builder` — Vehicles list screen  
File: `app/(tabs)/vehicles.tsx`, `src/components/vehicles/VehicleCard.tsx`  
- FlatList with pull-to-refresh
- Search bar (filter by name)
- Status filter chips
- Group filter
- Tenant brand styling

**T2.2** `ui-builder` — Vehicle detail screen  
File: `app/vehicle/[id].tsx`  
- Full vehicle info
- Current trip stats
- Quick actions (track, replay, alerts)

**T2.3** `dev-builder` — Trip history API integration  
File: `src/services/trips.ts`  
- Fetch trip history (last 30 days)
- React Query cache
- Tenant-scoped queries

**T2.4** `ui-builder` — Trip history list  
File: `src/components/vehicles/TripHistory.tsx`  
- Trip cards (date, distance, duration, route)
- Tap to replay

**Checkpoint:** Vehicle list + detail screens work for all tenants

---

### Phase 3: Offline Mode & Data Sync

**T3.1** `dev-builder` — Offline storage layer  
File: `src/lib/offline.ts`, `src/lib/db.ts`  
- AsyncStorage wrapper for positions
- Store last 7 days per vehicle
- JSON compression (reduce storage)
- Tenant-isolated storage namespaces

**T3.2** `dev-builder` — Sync manager  
File: `src/services/sync.ts`  
- Background sync when online
- Queue failed requests
- Sync status indicator
- Tenant-specific sync queues

**T3.3** `dev-builder` — Offline-first queries  
File: `src/hooks/useVehicles.ts`, `src/hooks/usePositions.ts`  
- React Query with AsyncStorage persistence
- Optimistic updates
- Conflict resolution

**T3.4** `ui-builder` — Offline indicator UI  
File: `src/components/common/OfflineIndicator.tsx`  
- Status bar banner when offline
- Sync status (syncing, offline, online)
- Tenant brand colors

**Checkpoint:** App works offline, syncs when back online, isolated per tenant

---

### Phase 4: Push Notifications & Alerts

**T4.1** `dev-builder` — Push notification setup  
File: `src/services/notifications.ts`, `app.config.js`  
- Expo Notifications config per tenant
- Request permissions
- Device token registration to backend (with tenantId)
- FCM/APNS per tenant app

**T4.2** `dev-builder` — Alert types & handlers  
File: `src/lib/alertHandlers.ts`  
- Geofence enter/exit
- Speeding
- Idle too long
- Low battery
- SOS button
- Tenant-specific alert rules

**T4.3** `ui-builder` — Alerts screen  
File: `app/(tabs)/alerts.tsx`, `src/components/alerts/AlertCard.tsx`  
- Notification center (list of alerts)
- Filter by type/vehicle
- Mark as read
- Navigate to vehicle/location

**T4.4** `dev-builder` — Local notifications  
File: `src/services/localNotifications.ts`  
- Schedule local reminders
- Trip end notifications
- Maintenance alerts

**Checkpoint:** Push notifications work per tenant, no cross-tenant leaks

---

### Phase 5: Background Location Tracking (Driver Mode)

**T5.1** `dev-builder` — Background location service  
File: `src/services/locationTracking.ts`  
- Expo Location background task
- Battery-optimized intervals (1-5 min based on movement)
- Send positions to tenant API

**T5.2** `dev-builder` — Driver mode state  
File: `src/stores/driverStore.ts`  
- Enable/disable tracking
- Current trip tracking
- Odometer
- Tenant-scoped trips

**T5.3** `ui-builder` — Driver mode toggle & UI  
File: `src/components/driver/DriverModeToggle.tsx`  
- Big "Start Trip" / "End Trip" button
- Current trip stats overlay
- Battery warning when low
- Tenant branding

**T5.4** `dev-builder` — Foreground service (Android)  
File: `android/app/src/main/AndroidManifest.xml`  
- Persistent notification when tracking
- Prevent app from being killed
- Tenant-branded notification

**Checkpoint:** Background tracking works per tenant, positions upload correctly

---

### Phase 6: Reports & Analytics

**T6.1** `ui-builder` — Reports screen  
File: `app/(tabs)/reports.tsx`  
- Report type selector (trip, fuel, idle, speeding)
- Date range picker
- Vehicle/group filter
- Tenant brand styling

**T6.2** `dev-builder` — Reports API integration  
File: `src/services/reports.ts`  
- Fetch pre-generated reports from backend
- Export to PDF (via backend)
- Tenant-scoped reports

**T6.3** `ui-builder` — Report cards & charts  
File: `src/components/reports/ReportCard.tsx`  
- Trip summary cards
- Simple charts (distance, fuel, violations)
- Export button

**T6.4** `ui-builder` — Analytics dashboard  
File: `src/components/reports/AnalyticsDashboard.tsx`  
- Driver score
- Top performers
- Fleet summary
- Tenant-specific metrics

**Checkpoint:** Reports load per tenant, no data leaks

---

### Phase 7: Geofences & Driver Management

**T7.1** `ui-builder` — Geofence list screen  
File: `app/geofences/index.tsx`  
- List of geofences with map preview
- Create/edit/delete
- Tenant-scoped geofences

**T7.2** `ui-builder` — Geofence editor  
File: `app/geofences/[id].tsx`  
- Draw circle/polygon on map
- Set alerts (enter/exit)
- Assign vehicles

**T7.3** `ui-builder` — Driver management screen  
File: `app/drivers/index.tsx`  
- Driver list
- Assign to vehicles
- Driver score display
- Tenant-scoped drivers

**T7.4** `ui-builder` — Driver detail  
File: `app/drivers/[id].tsx`  
- Profile info
- Assigned vehicles
- Performance stats

**Checkpoint:** Geofences & drivers manageable, tenant-isolated

---

### Phase 8: Settings & Polish

**T8.1** `ui-builder` — Settings screen  
File: `app/(tabs)/profile.tsx`, `app/settings.tsx`  
- Account info
- Notification preferences
- Offline settings (storage limit)
- Language (Thai/English)
- Dark mode toggle
- Tenant branding displayed

**T8.2** `ui-builder` — Onboarding flow  
File: `app/(onboarding)/_layout.tsx`  
- Welcome screens (tenant-branded)
- Permission requests (location, notifications)
- Login/signup (tenant-specific auth)

**T8.3** `dev-builder` — Dynamic app icon & splash per tenant  
File: `scripts/generateAssets.js`, `config/tenants/*/assets/`  
- Generate icon.png, splash.png per tenant
- Adaptive icon (Android)
- Build-time asset injection

**T8.4** `dev-builder` — Error boundaries & logging  
File: `src/lib/errorHandler.ts`  
- Sentry integration (optional)
- Crash reporting
- User feedback form
- Tenant context in error logs

**Checkpoint:** App polished per tenant, branding consistent

---

### Phase 9: Build & Deploy (Multi-Tenant)

**T9.1** `platform-adapter` — Multi-tenant EAS Build setup  
File: `eas.json`, `app.config.js`, `scripts/buildTenant.sh`  
- Build script: `./scripts/buildTenant.sh tenant1 production`
- Auto-generates app.json per tenant
- Environment variables per tenant

**T9.2** `test-runner` — Build 2 test tenant Android APKs  
Command: `eas build --platform android --profile tenant1-prod`  
Command: `eas build --platform android --profile tenant2-prod`  
- Verify different bundle IDs, icons, colors

**T9.3** `test-runner` — Build 2 test tenant iOS IPAs  
Command: `eas build --platform ios --profile tenant1-prod`  
Command: `eas build --platform ios --profile tenant2-prod`  
- Verify different bundle IDs, icons, colors

**T9.4** `dev-builder` — Tenant onboarding documentation  
File: `docs/TENANT_ONBOARDING.md`, `docs/BUILD_NEW_TENANT.md`  
- How to add new tenant
- Checklist (config, assets, build, submit)
- App Store Connect / Play Console setup per tenant

**Checkpoint:** Can build N tenant apps from 1 codebase, ready for stores

---

## Status

`approved`

---

## Notes

**Multi-Tenant Strategy:**
- **1 codebase** → N tenant apps
- **Build-time branching** via EAS profiles
- **Runtime tenant detection** via config
- **Storage isolation** via tenant-prefixed keys
- **API isolation** via tenantId in auth headers

**Tenant Config Example:**
```json
{
  "id": "tenant1",
  "name": "GPS Thailand",
  "bundleId": "com.bellerox.gps.tenant1",
  "apiUrl": "https://api.gpsthailand.com",
  "colors": {
    "primary": "#1E40AF",
    "secondary": "#3B82F6"
  },
  "logo": "config/tenants/tenant1/logo.png"
}
```

**Estimated time:** 4-5 days (with multi-tenant setup)  
**Testing:** Test with 2 tenants to verify isolation
