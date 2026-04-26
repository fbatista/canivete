# Leagues & Circuits — Implementation Plan

> **Last Updated:** 2026-04-26
> **Current State:** [leagues-and-circuits-status.md](leagues-and-circuits-status.md)
> **Goal:** Add leagues and circuits, refactor tournaments to extend from a shared Event base (STI).
> **Tests:** 101 runs, 338 assertions, 0 failures, 0 errors, 0 skips

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

## 🟡 Phase 4 — League Jobs & Pairing (ALMOST COMPLETE)

### 4.1 Job: `Leagues::StartPlayRoundJob` ✅
- Creates new Swiss play rounds for scheduled mode

### 4.2 Job: `Leagues::CreatePickupPodJob` ❌
- **Not yet implemented** — pick-up play pod creation

### 4.3 Job: `Leagues::StartSingleEliminationRoundJob` ✅
- Exists as `StartFinalsRoundJob` — creates finals single-elimination round

### 4.4 Job: `Leagues::FinishLeagueJob` ✅
- Sets final positions, triggers circuit integration (Phase 6)

### 4.5 Update `League` model ✅
- ✅ State machine defined (`draft → registration_open → registration_closed → play → finals → finished/canceled`)
- ✅ `enum :play_mode, { scheduled: 0, pickup: 1 }` — added with `prefix: true`
- ❌ `validates :wager_percentage, numericality: ...` — not added

### 4.6 Update `EventParticipant` for league scoring ✅
- ✅ `rank_score` league-aware delegation (returns `league_score` for leagues)
- ✅ `before_save :reset_rank_score_cache` callback when `league_score` changes

### 4.7 Tests ⏳
- ✅ `test/models/league_test.rb`, `test/models/circuit_test.rb`
- ❌ `test/jobs/leagues/*_test.rb` — job tests not yet written

### 4.8 Create `CircuitStanding` model ✅
- ✅ `app/models/circuit_standing.rb` with `ranked` and `for_circuit` scopes
- ✅ `Circuit` model updated with `has_many :circuit_standings, dependent: :destroy`

---

## ❌ Phase 5 — League Controllers, Routes & Views (NOT STARTED)

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

## ❌ Phase 6 — Circuit Scoring Service (NOT STARTED)

### 6.1 Model: `CircuitStanding`
```ruby
class CircuitStanding < ApplicationRecord
  belongs_to :circuit
  belongs_to :player
  scope :ranked, -> { order(points: :desc) }
  scope :for_circuit, ->(circuit) { where(circuit: circuit) }
end
```

### 6.2 Update `Circuit` model
- Add `has_many :circuit_standings, dependent: :destroy`
- Add `standings` and `update_standings!` methods

### 6.3 Service: `Circuits::CalculatePoints`
```ruby
module Circuits
  class CalculatePoints
    def initialize(circuit, tournament)
      @circuit = circuit
      @tournament = tournament
    end

    def award_points!
      participants = @tournament.event_participants
        .where.not(final_position: nil)
        .order(final_position: :asc)

      total = participants.size
      participants.each do |ep|
        standing = @circuit.circuit_standings.find_or_initialize_by(player: ep.player)
        position_points = (total - ep.final_position + 1).to_f
        standing.points += position_points
        standing.events_count += 1
        standing.save!
      end
    end
  end
end
```

### 6.4 Job: `Circuits::UpdateStandingsJob`
```ruby
module Circuits
  class UpdateStandingsJob < ApplicationJob
    def perform(circuit, tournament)
      Circuits::CalculatePoints.new(circuit, tournament).award_points!
    end
  end
end
```

### 6.5 Hook: Update circuit when tournament finishes
- In `FinishTournamentJob`, call `Circuits::UpdateStandingsJob.perform_now(tournament.circuit, tournament)`

### 6.6 Tests
- `test/models/circuit_test.rb` (update), `test/models/circuit_standing_test.rb`
- `test/services/circuits/calculate_points_test.rb`
- `test/jobs/circuits/update_standings_job_test.rb`

---

## ❌ Phase 7 — Polish & Cross-cutting (NOT STARTED)

| Item | Details |
|------|---------|
| **7.1** Unified `/events` index | Show both tournaments and leagues; filter by type, organizer, date |
| **7.2** Organizer dashboard | All events + circuits in one view with quick actions |
| **7.3** League-specific UI | Standings table, play mode indicator, wager display, pick-up pod button |
| **7.4** Circuit-specific UI | Standings leaderboard, tournament results history, points breakdown |
| **7.5** Tournament model cleanup | Ensure `Tournament` uses `event.class` for shared constants |
| **7.6** Circuit column on events | `circuit_id` already exists; backfill if needed |
| **7.7** Code quality | Run `bin/rubocop`, `bin/brakeman` |
| **7.8** System tests | League creation, circuit standings, pick-up pod flow |

---

## Open Design Decisions

1. **League top cut size** — Mirror tournament thresholds or have own? Configurable per-league?
2. **Point wager partial draws** — Pod has mix of wins and draws (not all draw)? Need exact rule.
3. **Circuit points formula** — Simple `total - position + 1` or logarithmic/weighted? Configurable?
4. **Can leagues belong to circuits?** Currently only tournaments do. If leagues should feed into circuit standings, `Event` needs `belongs_to :circuit`.
5. **Pick-up play: concurrent pods** — Multiple pods running simultaneously. How does UI show ongoing pods and available players?
6. **Wager percentage scope** — Per-league or global? Currently per-event on `events` table.
