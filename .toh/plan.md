# Plan — GT06 cars frozen on map (time.override + maxSpeed lockout)

Status: approved
Repo: infrastructure (Traccar device attributes + scripts) · no web/mobile code change

## Goal
Cars that report on time but stay at the same spot on the map start moving again, beginning with 70-9915.

## Root cause (proven 2026-10-12)
- 70-9915 (id 371) froze at 15.91303,100.60860 showing **63 km/h** from 2026-10-08 14:45 to 2026-10-10 13:18 (~46 h). On 10-09 it had 0 GPS rows saved; only heartbeat/status rows that copy the old coordinate.
- The Traccar log for that IMEI shows `filtered by MaxSpeed` 1,158 times on 10-09 and 765 on 10-10, so the real GPS fixes arrived but were dropped.
- `FilterHandler.filterMaxSpeed` (decompiled 6.14.5) computes `distance / (fixTime − lastFixTime)`.
- The device has `time.override=serverTime` (set 2026-09-24 for broken clocks). Under that setting, every GT06 heartbeat (packet 0x13) is saved with the old coordinate and a **fresh** fixTime.
- The next real fix then comes a few km from the frozen point only seconds after a heartbeat, so the computed speed is above 250 km/h and the fix is filtered. The next heartbeat refreshes the frozen point again, so it locks itself until the car happens to come back near the frozen spot.
- In the last 7 days, frozen hours while showing a speed above 9 km/h:
  - override devices: 371 = 121 h · 294 = 149 h · 168 = 120 h · 262 = 99 h · 289 = 84 h · 221 = 63 h · 369 = 62 h · 48 = 51 h
  - decoder.timezone devices (e.g. 70-9917, id 372): 0 h
- 70-9917 has no freeze in 7 days (it moved every working day, totalDistance 337 → 2,142 km). It is just parked now.
- Several override devices have a healthy clock that runs a constant +7.0 h. Their raw GT06 time is local time: 371, 369, 294, 370, 205, 181, 224, 225. They never needed override. `decoder.timezone=GMT+07:00` fixes them properly, the same as 70-9917.

## Done When
- No device with a stable +7 h clock has `time.override`; they all use `decoder.timezone=GMT+07:00`.
- Truly broken-clock devices keep `time.override` but can no longer lock (per-device `filter.maxSpeed` neutralised).
- The Traccar log has ~0 `MaxSpeed` filters for the affected IMEIs over 1 h after the change.
- In daytime, 70-9915 shows multiple distinct coordinates while ignition is on.

## Phase 1 — Classify (read-only)
- [x] T101 dev-builder — run `infrastructure/scripts/tz-audit.sql` on VM (nohup → file → scp) and confirm, for every `time.override` device, whether its raw-clock offset is a constant +7 h or broken
- [ ] Checkpoint: list A (stable +7 h) and list B (broken) written into `infrastructure/scripts/override-lockout-fix.sql` header

## Phase 2 — Fix (production device attributes, no Traccar restart)
- [x] T201 dev-builder — `override-lockout-fix.sql`: list A → drop `time.override`, set `decoder.timezone=GMT+07:00`; list B → add `filter.maxSpeed=100000` (per-device DEVICE key, neutralises the lockout)
- [x] T202 dev-builder — apply via Traccar API `PUT /api/devices/{id}` (cache refreshes live, no restart); keep before/after JSON in `/tmp` for rollback
- [ ] Checkpoint: `GET /api/devices` shows the new attributes on every listed device

## Phase 3 — Verify + record
- [x] T301 test-runner — 1 h after apply: grep today's tracker-server.log; MaxSpeed count for list A+B IMEIs ≈ 0; new GT06 rows for 371 carry distinct lat/lon
- [ ] T302 test-runner — daytime (after 07:00 ICT) re-run the frozen-hours script; 371/294/168/262 < 1 h
- [x] T303 plan-orchestrator — update memory (clock-drift note + new lockout lesson), tz-audit.sql comment, commit + push
- [ ] Checkpoint: all Done When met

## Rollback
Re-PUT saved before-JSON per device (restores old attributes instantly).

## Out of scope
Positions already dropped by the filter on 10-04 to 10-11 are not stored. The log has them, but restoring them is a separate job.
