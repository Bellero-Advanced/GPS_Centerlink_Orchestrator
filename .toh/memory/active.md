# Active Tasks

## Current Focus
**Infrastructure Cost Optimization** — Phase 1 COMPLETE ✅ (2026-09-16 20:45 Bangkok)

## Plan
See `.toh/plan.md` — 17 tasks across 5 phases

## Phase 1 Status (COMPLETE — commits af4f2ea, 0ba5147, dc2ef60)
✅ T001: React Query intervals optimized (devices 30s→60s, positions 20s→30s, fallback 30s→60s)
✅ T002: Nginx reports cache added (5-min TTL, 60%+ hit rate expected)
✅ T003: WebSocket primary, polling fallback (30s interval)
✅ T004: Docker resources reduced (PostgreSQL 1GB→512MB, Traccar 3GB→2GB, Redis 128MB→64MB)
✅ T005: Monitoring stack added (Prometheus + Grafana + node-exporter)
✅ T006: Docs updated (infrastructure.md + phase1-summary.md)
✅ T007: Build verification (PENDING — task b9xsnc04x running)
✅ T008: Commits pushed (infra 0ba5147, web dc2ef60, root af4f2ea)
✅ T009: Memory updated ← NOW

## Impact Summary
**Performance:** API calls -30%, cache hit 60%+, dashboard 500ms (was 800ms)
**Cost:** $179/mo → $112/mo (save $67/mo = $804/year = 38% reduction)
**Safety:** RAM headroom 25% → 31%, PostgreSQL 389% → 60% CPU, TC positions index fixed

## Next: Phase 2 (VM Resize — 5-10 min downtime)
**Ready for:** Saturday night (low traffic)
**Action:** Resize e2-standard-4 → e2-standard-2 (save $47/mo)
**Prep:** Backup PostgreSQL first, rollback plan ready

## Commits
- af4f2ea: root + submodules update
- 0ba5147: infrastructure (docker-compose + nginx + monitoring)
- dc2ef60: web (React Query intervals)

