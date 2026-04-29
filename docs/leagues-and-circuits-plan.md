# Leagues & Circuits — Implementation Plan

> **Last Updated:** 2026-04-26
> **Current State:** [leagues-and-circuits-status.md](leagues-and-circuits-status.md)
> **Goal:** Add leagues and circuits, refactor tournaments to extend from a shared Event base (STI).
> **Tests:** 132 runs, 417 assertions, 0 failures, 0 errors, 0 skips
> **Commits:** Small, digestible commits with clear, concise messages. One logical change per commit.
> **Progression:** Keep both the plan and state files updated.

---

## Dependency Graph

```
Phase 1 (Cleanup)
    │
    ▼
Phase 2 (Migrations)
    │
    ├────► Phase 3 (Point Wager Scoring)
    │           │
    │           ▼
    │     Phase 4 (League Jobs)
    │           │
    │           ▼
    │     Phase 5 (League UI)
    │
    ├────► Phase 6 (Circuit Scoring)
    │
    └────► Phase 7 (Polish)
```

Phases 3→4→5 and Phase 6 are independent of each other and could be parallelized after Phase 2.

---

## ✅ Phase 1 — Cleanup & Bugfixes (COMPLETE)

### 1.1 Fix `Pod` model references ✅
- `has_one :event, through: :round` (was `has_one :tournament`)
- Added `Pod.finished` scope

### 1.2 Fix `SwissRound` validation ✅
- Already correct (`scope: :event_id`)

### 1.3 Add default `advance_tournament!` to `Round` ✅
- Added `def advance_tournament!; end` no-op to `Round`

### 1.4 Create `Room` model ✅
- `app/models/room.rb` created

### 1.5 Rename old view directories ✅
- All `tournament_participant` → `event_participant` renames done

### 1.6 Fix the flunking test ✅
- `StartSingleEliminationRoundJobTest` fixed

### 1.7 Add League & Circuit fixtures ✅
- `test/fixtures/leagues.yml` — `standard_league`
- `test/fixtures/circuits.yml` — `standard_circuit`

---

## ✅ Phase 2 — Database Schema (COMPLETE)

All migrations created and applied:

| Migration | Column | Purpose |
|-----------|--------|---------|
| `add_play_mode_to_events` | `play_mode` enum | Scheduled vs pick-up league mode |
| `add_league_fields_to_rounds` | `is_play_round`, `is_finals_round` | Round type tracking |
| `add_league_score_to_event_participants` | `league_score` (default 1000.0) | Player score tracking |
| `add_circuit_id_to_events` | `circuit_id` FK | Circuit association |
| `create_circuit_standings` | New table | Player standings per circuit |
| `add_final_position_to_event_participants` | `final_position` | Final placement |
| `add_wager_percentage_to_events` | `wager_percentage` | Point wager % |

---

## ✅ Phase 3 — Point Wager Scoring (COMPLETE)

### 3.1 Service ✅
- `Scoring::PointWager` — forward/reverse direction averaging, winner-takes-all, draw splitting
- `recalculate_all!`, `compute_scores(direction)`, `apply_pod_result(pod, scores)`

### 3.2 Migration ✅ (see Phase 2)

### 3.3 Hook: Recalculate after result submission ⏳
- **TODO:** Add `Scoring::PointWager` trigger in `SubmitResultJob` when event is a League in play state

### 3.4 Scope additions ✅
- `Round.play_rounds`, `Round.finals_rounds`

### 3.5 Tests ✅
- 8 passing tests in `test/services/scoring/point_wager_test.rb`

---

## ✅ Phase 4 — League Jobs & Pairing (COMPLETE)

### 4.1 Job: `Leagues::StartPlayRoundJob` ✅
- Creates new Swiss play rounds for scheduled mode

### 4.2 Job: `Leagues::CreatePickupPodJob` ✅
- Picks available (unseated) players and groups them into pods
- Uses existing unpublished round or creates one if needed
- Respects minimum pod size (3 players)

### 4.3 Job: `Leagues::StartFinalsRoundJob` ✅
- Exists as `StartFinalsRoundJob` — creates finals single-elimination round
- Fixed to use `SingleEliminationRound` instead of `SwissRound`

### 4.4 Job: `Leagues::FinishLeagueJob` ✅
- Sets final positions, triggers circuit integration (Phase 6)

### 4.5 Update `League` model ✅
- ✅ State machine defined (`draft → registration_open → registration_closed → play → finals → finished/canceled`)
- ✅ `enum :play_mode, { scheduled: 0, pickup: 1 }` — added with `prefix: true`
- ✅ `validates :wager_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_blank: true }`

### 4.6 Update `EventParticipant` for league scoring ✅
- ✅ `rank_score` league-aware delegation (returns `league_score` for leagues)
- ✅ `before_save :reset_rank_score_cache` callback when `league_score` changes

### 4.7 Tests ✅
- ✅ `test/models/league_test.rb` — state transitions, wager validation, play_mode enum
- ✅ `test/models/circuit_test.rb` — associations, standings, update_standings
- ✅ `test/jobs/leagues/start_play_round_job_test.rb`
- ✅ `test/jobs/leagues/start_finals_round_job_test.rb`
- ✅ `test/jobs/leagues/finish_league_job_test.rb`
- ✅ `test/jobs/leagues/create_pickup_pod_job_test.rb`

### 4.8 Create `CircuitStanding` model ✅
- ✅ `app/models/circuit_standing.rb` with `ranked` and `for_circuit` scopes
- ✅ `Circuit` model updated with `has_many :circuit_standings, dependent: :destroy`

---

## ✅ Phase 5 — Controllers, Routes & Views (COMPLETE)

### 5.1 Routes
```ruby
resources :leagues, only: %i[index show] do
  resources :rounds do
    resources :pods
  end
  resources :event_participants do
    collection { get "me" }
  end
end

namespace :organizer do
  resources :leagues do
    resources :infractions, only: %i[new create]
    resources :event_participants do
      resources :infractions, only: %i[index destroy]
    end
    resources :rounds do
      resources :seatings, only: [] { patch :swap, on: :collection }
      resources :pods do
        resources :results
        resources :infractions, only: %i[new create]
      end
    end
    post :create_pickup_pod, on: :member
  end
  resources :circuits do
    resources :tournaments, only: %i[new create]
  end
end
```

### 5.2 Public Controllers
- `LeaguesController` — mirror `TournamentsController` (index, show)
- `Organizer::LeaguesController` — mirror `Organizer::TournamentsController` (CRUD, state advancement, `create_pickup_pod`)

### 5.3 Circuit Controller
- `Organizer::CircuitsController` — index, show, new, create, update
- Show displays standings ranked

### 5.4 Views to create
```
app/views/leagues/
app/views/organizer/leagues/
app/views/organizer/circuits/
```

### 5.5 Shared Event Components (consider later)
- `app/views/shared/_event_card.html.erb`
- `app/views/shared/_event_header.html.erb`
- `app/views/shared/_event_participants_table.html.erb`

---

## ✅ Phase 6 — Circuit Scoring Service (COMPLETE)

### 6.1 Model: `CircuitStanding`
```ruby
class CircuitStanding < ApplicationRecord
  belongs_to :circuit
  belongs_to :player
  scope :ranked, -> { order(points: :desc) }
  scope :for_circuit, ->(circuit) { where(circuit: circuit) }
end
```

### 6.2 Update `Circuit` model ✅
- ✅ `has_many :circuit_standings, dependent: :destroy`
- ✅ `standings` and `update_standings!` methods
- ✅ `for_organizer` scope

### 6.3 Service: `Circuits::CalculatePoints` ✅
- `award_points!` — awards `total - position + 1` points per participant
- Supports point accumulation across multiple events
- Uses `find_or_initialize_by` pattern

### 6.4 Job: `Circuits::UpdateStandingsJob` ✅
- Wraps `Circuits::CalculatePoints` in an async job

### 6.5 Hook: Update circuit when tournament finishes ✅
- In `FinishLeagueJob`, calls `Circuits::UpdateStandingsJob.perform_now(league.circuit, league)`
- Also hooks into `FinishTournamentJob` for tournaments with circuits

### 6.6 Tests ✅
- ✅ `test/models/circuit_test.rb` — associations, standings, update_standings
- ✅ `test/services/circuits/calculate_points_test.rb` — 7 tests
- ✅ `test/jobs/circuits/update_standings_job_test.rb`

---

## 🔄 Phase 7 — Polish & Cross-cutting (IN PROGRESS — 7/8 items done)

| Item | Details |
|------|---------|
| **7.1** Unified `/events` index | ✅ Created `EventsController`, unified index at `/events`, root route updated |
| **7.2** Organizer dashboard | ✅ Fixed `organizer_path` route, organizer now routes to tournaments#index |
| **7.3** League-specific UI | ✅ Standings table, play mode indicator, wager display, pick-up pod button added |
| **7.4** Circuit-specific UI | ✅ Circuits now show leagues + tournaments, `has_many :leagues` association added |
| **7.5** Tournament model cleanup | ✅ Added `number_of_swiss_rounds` and `number_of_single_elimination_rounds` to Event base class |
| **7.6** Circuit column on events | ✅ `circuit_id` column exists on events table |
| **7.7** Code quality | ✅ `bin/rubocop` — 110 offenses (down from 128); most pre-existing in old migrations |
| **7.8** System tests | ⚠️ Integration test files created but Herb gem interferes with ERB rendering in tests; need to run in a browser-capable environment with Chrome/Playwright |

---

## Open Design Decisions

1. **League top cut size** — Mirror tournament thresholds or have own? Configurable per-league?
2. **Point wager partial draws** — Pod has mix of wins and draws (not all draw)? Need exact rule.
3. **Circuit points formula** — Simple `total - position + 1` or logarithmic/weighted? Configurable?
4. **Can leagues belong to circuits?** Currently only tournaments do. If leagues should feed into circuit standings, `Event` needs `belongs_to :circuit`.
5. **Pick-up play: concurrent pods** — Multiple pods running simultaneously. How does UI show ongoing pods and available players?
6. **Wager percentage scope** — Per-league or global? Currently per-event on `events` table.
