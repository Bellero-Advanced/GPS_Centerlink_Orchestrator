# PART V: Enterprise Features (Phase 8-11)

**Start:** 2026-08-25  
**Target:** Complete all 4 phases without stopping  
**Strategy:** Code-first, infrastructure-light (deploy on existing VM)

---

## Phase 8: White-Label Platform ⏳

### Level 1: Custom Domains (Skip - needs production Nginx)
- ⏳ Multi-domain Nginx config (production only)
- ⏳ DNS verification API
- ⏳ Auto SSL provisioning
- **Decision:** Document only, implement when first reseller signs up

### Level 2: Branding ✅ DO THIS
- ✅ Branding config in tenants table
- ✅ Logo upload API (store in /public/uploads)
- ✅ Theme system (colors, company name)
- ✅ Frontend: Dynamic branding from tenant context
- ✅ Email templates with custom branding

### Level 3: API Keys ✅ DO THIS
- ✅ API keys table (CRUD)
- ✅ API key authentication middleware
- ✅ Scoped permissions per key
- ✅ Rate limiting per key (simple in-memory)
- ✅ API key management UI

---

## Phase 9: Advanced Analytics ✅ DO THIS

### T9.1: Analytics Schema
- ✅ Create aggregated analytics tables
- ✅ Daily/monthly rollups
- ✅ Driver behavior scoring

### T9.2: Analytics API
- ✅ Endpoints for dashboard charts
- ✅ Trend analysis
- ✅ Comparison reports

### T9.3: Analytics UI
- ✅ Charts (Recharts already installed)
- ✅ Filters (date range, vehicle groups)
- ✅ Export to PDF

---

## Phase 10: Mobile App (Skip - needs separate work)
- ⏳ Offline mode (complex, needs IndexedDB + sync)
- ⏳ Push notifications (needs FCM setup)
- ⏳ Background tracking (battery optimization)
- **Decision:** Defer to dedicated mobile sprint

---

## Phase 11: API Gateway & Rate Limiting ✅ DO THIS

### T11.1: Rate Limiting Middleware
- ✅ Express rate limiting (per IP, per user, per API key)
- ✅ Redis-free implementation (in-memory Map)
- ✅ 429 responses with Retry-After

### T11.2: API Versioning
- ✅ /api/v1/ structure
- ✅ Version detection middleware
- ✅ Deprecation warnings

### T11.3: API Documentation
- ✅ OpenAPI/Swagger spec
- ✅ Auto-generated docs UI
- ✅ Example requests

---

## Implementation Plan

**Phase 8 (Branding + API Keys):** ~12 files
- 2 migrations (branding, api_keys)
- 3 API routes
- 4 frontend components
- 3 services

**Phase 9 (Analytics):** ~8 files
- 2 migrations (analytics tables)
- 2 API routes
- 4 frontend components

**Phase 11 (Rate Limiting + Versioning):** ~6 files
- 1 middleware
- 1 API docs setup
- 4 documentation files

**Total:** ~26 files, ~3,000 lines of code

---

## What We Skip (For Now)

1. **Custom Domains** - needs production Nginx access
2. **Mobile App Features** - separate sprint
3. **Payment Integration** - wait for real customers
4. **Heavy Analytics** - start simple, scale later

---

## Success Criteria

**Phase 8:**
- ✅ Tenants can customize logo & colors
- ✅ API keys work for authentication
- ✅ UI shows custom branding

**Phase 9:**
- ✅ Analytics dashboard with charts
- ✅ Driver scoring algorithm
- ✅ Export reports to PDF

**Phase 11:**
- ✅ Rate limiting works (100 req/min per user)
- ✅ API docs accessible
- ✅ Versioned endpoints

---

เริ่มทำเลย!
