# Leagues & Circuits Refactoring Status

> **Last Updated:** 2026-04-26
> **Goal:** Add leagues and circuits, refactor tournaments to extend from a shared Event base (STI).
> **Tests:** 132 runs, 417 assertions, 0 failures, 0 errors, 0 skips

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
**4.2 `Leagues::CreatePickupPodJob`** ✅ — Picks available players, creates pods in existing or new round
**4.3 `Leagues::StartFinalsRoundJob`** ✅ — Fixed to create `SingleEliminationRound` (was incorrectly using `SwissRound`)
**4.4 `Leagues::FinishLeagueJob`** ✅ — Finalizes league, triggers circuit integration

### Phase 1.7 — Fixtures & Model Tests

- ✅ `test/fixtures/leagues.yml` — Updated with 4 event participants
- ✅ `test/fixtures/circuits.yml`
- ✅ `test/models/league_test.rb` — State transitions, wager validation, play_mode enum
- ✅ `test/models/circuit_test.rb` — Associations, standings, update_standings
- ✅ `app/models/circuit_standing.rb` — Created with `ranked`/`for_circuit` scopes
- ✅ `app/models/league.rb` — `play_mode` enum, wager validation
- ✅ `test/jobs/leagues/start_play_round_job_test.rb`
- ✅ `test/jobs/leagues/start_finals_round_job_test.rb`
- ✅ `test/jobs/leagues/finish_league_job_test.rb`
- ✅ `test/jobs/leagues/create_pickup_pod_job_test.rb`

---

## ⏳ In Progress / Remaining

### Phase 5 — Controllers, Routes & Views

| Item | Status |
|------|--------|
| `LeaguesController` (public) | ✅ Created |
| `Organizer::LeaguesController` | ✅ Created |
| `CircuitsController` (public) | ✅ Created |
| `Organizer::CircuitsController` | ✅ Created |
| Routes for leagues/circuits | ✅ Added |
| View templates | ✅ Created |

### Phase 6 — Circuit Scoring Service

| Item | Status |
|------|--------|
| `Circuits::CalculatePoints` service | ✅ Implemented — 7 tests |
| `Circuits::UpdateStandingsJob` | ✅ Implemented — 2 tests |
| Hook in `FinishLeagueJob` | ✅ Implemented — 2 tests |
| Hook in `FinishTournamentJob` | ✅ Already existed |
| Circuit model `number_of_swiss_rounds` | ✅ Added to Event base class |

### Phase 7 — Polish

| Item | Status |
|------|--------|
| Unified `/events` index (7.1) | ✅ `EventsController` created, root route updated |
| Organizer dashboard (7.2) | ✅ `organizer_path` route fixed |
| League-specific helpers/UI (7.3) | ✅ Standings table, play mode indicator, wager display, pick-up pod |
| Circuit-specific helpers/UI (7.4) | ✅ Circuits now include leagues, `has_many :leagues` added |
| Tournament model cleanup (7.5) | ✅ Added `number_of_swiss_rounds` and `number_of_single_elimination_rounds` to Event base class |
| Circuit column on events (7.6) | ✅ column exists |
| Code quality `bin/rubocop` (7.7) | ⚠️ 110 offenses (down from 128; most pre-existing in migrations) |
| System tests (7.8) | ❌ |

---

## ⏳ Remaining

### Phase 7 — Polish (partial)
- [x] 7.1 Unified `/events` index
- [x] 7.2 Organizer dashboard route
- [x] 7.3 League-specific UI
- [x] 7.4 Circuit-specific UI
- [x] 7.7 Code quality — 110 offenses (down from 128)
- [ ] 7.8 System tests — League creation, circuit standings, pick-up pod flow

---

## Summary

| Phase | Status |
|-------|--------|
| Phase 1 — Cleanup | ✅ Complete |
| Phase 2 — Migrations | ✅ Complete |
| Phase 3 — Point Wager | ✅ Complete |
| Phase 4 — Jobs & Models | ✅ Complete |
| Phase 5 — Controllers/Views | ✅ Complete |
| Phase 6 — Circuit Scoring | ✅ Complete |
| Phase 7 — Polish | 🔄 In progress (7/8 items done) |

**Test health:** All 132 unit tests passing (132 runs, 417 assertions, 0 failures, 0 errors, 0 skips). System tests require Chromium/Playwright browser not available in this environment.
