# Leagues & Circuits Refactoring Status

> **Last Updated:** 2026-04-26
> **Goal:** Add leagues and circuits, refactor tournaments to extend from a shared Event base (STI).
> **Tests:** 101 runs, 338 assertions, 0 failures, 0 errors, 0 skips

---

## ✅ Completed

### Phase 1 — Cleanup & Bugfixes

**1.1 Pod model references** ✅
- `has_one :tournament, through: :round` → `has_one :event, through: :round`
- Added `Pod.finished` scope

**1.3 Round base class** ✅
- Added default `advance_tournament!` (no-op) to `Round`

**1.4 Room model** ✅
- Created `app/models/room.rb`

**1.5 View directory renames** ✅
- `tournament_participants/` → `event_participants/`
- All partials and references updated

**1.6 Flunking test** ✅
- Fixed `StartSingleEliminationRoundJobTest`

### Phase 2 — Database Schema (Migrations)

**All migrations created and run:**
| Migration | Description |
|-----------|-------------|
| `add_play_mode_to_events` | `play_mode` enum (scheduled/pickup) on events table |
| `add_league_fields_to_rounds` | `is_play_round`, `is_finals_round` on rounds table |
| `add_league_score_to_event_participants` | `league_score` column (default 1000.0) |
| `add_circuit_id_to_events` | `circuit_id` FK on events table |
| `create_circuit_standings` | Circuit standings table with unique index |
| `add_final_position_to_event_participants` | `final_position` column |
| `add_wager_percentage_to_events` | `wager_percentage` decimal on events table |

### Phase 3 — Point Wager Scoring

**3.1 Service** ✅
- `Scoring::PointWager` — `recalculate_all!`, `compute_scores(direction)`, `apply_pod_result(pod, scores)`
- Forward/reverse direction averaging implemented
- Winner-takes-all and all-draw splitting implemented

**3.2 Migration** ✅ (see Phase 2)

**3.4 Scopes** ✅
- `Round.play_rounds`, `Round.finals_rounds` added

**3.5 Tests** ✅
- 8 passing tests: starting points, winner takes all, draw split, forward/reverse averaging, multi-round accumulation, all-draw pot calculation

### Phase 4 — League Jobs

**4.1 `Leagues::StartPlayRoundJob`** ✅ — Creates new Swiss play rounds
**4.2 `Leagues::CreatePickupPodJob`** ⏳ — Not yet implemented
**4.3 `Leagues::StartSingleEliminationRoundJob`** ✅ (exists as `StartFinalsRoundJob`) — Creates finals single-elimination round
**4.4 `Leagues::FinishLeagueJob`** ✅ — Finalizes league, sets positions

### Phase 1.7 — Fixtures & Model Tests

- ✅ `test/fixtures/leagues.yml`
- ✅ `test/fixtures/circuits.yml`
- ✅ `test/models/league_test.rb`
- ✅ `test/models/circuit_test.rb`
- ⏳ `app/models/circuit_standing.rb` — Model file not yet created (table exists)
- ⏳ `app/models/league.rb` — `play_mode` enum not yet defined in code

---

## ⏳ In Progress / Remaining

### Phase 5 — Controllers, Routes & Views

| Item | Status |
|------|--------|
| `LeaguesController` (public) | ❌ Missing |
| `Organizer::LeaguesController` | ❌ Missing |
| `CircuitsController` (public) | ❌ Missing |
| `Organizer::CircuitsController` | ❌ Missing |
| Routes for leagues/circuits | ❌ Missing |
| All view templates | ❌ Missing |

### Phase 6 — Circuit Scoring Service

| Item | Status |
|------|--------|
| `CircuitStanding` model | ❌ Missing (table exists) |
| `Circuits::CalculatePoints` service | ❌ Missing |
| `Circuits::UpdateStandingsJob` | ❌ Missing |
| Hook in tournament finish | ❌ Missing |

### Phase 7 — Polish

| Item | Status |
|------|--------|
| Unified `/events` index (7.1) | ❌ |
| Organizer dashboard (7.2) | ❌ |
| League-specific helpers/UI (7.3) | ❌ |
| Circuit-specific helpers/UI (7.4) | ❌ |
| Tournament model cleanup (7.5) | ⏳ |
| Circuit column on events (7.6) | ✅ column exists |
| Code quality `bin/rubocop` (7.7) | ⚠️ 23 offenses (metrics mostly) |
| System tests (7.8) | ❌ |

---

## ⚠️ Partially Done

### Phase 4 — League Model
- ✅ `League < Event` with state machine (`draft → registration_open → registration_closed → play → finals → finished/canceled`)
- ⏳ `enum :play_mode, { scheduled: 0, pickup: 1 }` — column exists but enum not defined in model
- ⏳ `EventParticipant#rank_score` — returns tournament scoring; needs league-aware delegation

---

## Summary

| Phase | Status |
|-------|--------|
| Phase 1 — Cleanup | ✅ Complete |
| Phase 2 — Migrations | ✅ Complete |
| Phase 3 — Point Wager | ✅ Complete |
| Phase 4 — Jobs | 🟡 Mostly done (missing CreatePickupPodJob, play_mode enum) |
| Phase 5 — Controllers/Views | ❌ Not started |
| Phase 6 — Circuit Scoring | ❌ Not started |
| Phase 7 — Polish | ❌ Not started |

**Test health:** All 101 tests passing.
