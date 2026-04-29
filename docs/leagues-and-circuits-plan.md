# Leagues & Circuits — Implementation Plan

> **Based on:** `docs/leagues-and-circuits-status.md`
> **Date:** 2026-04-25
> **Goal:** Complete the leagues and circuits feature set, fix STI refactoring gaps.

---

## Phase 1 — Cleanup & Bugfixes

Unblock everything, low risk, no new features.

### 1.1 Fix `Pod` model references
**File:** `app/models/pod.rb`

- Replace `has_one :tournament, through: :round` → `has_one :event, through: :round`
- Replace `tournament.class::PAIR_DOWN_DEVIATION_PERCENT` → `event.class::PAIR_DOWN_DEVIATION_PERCENT`
  - **Note:** `Tournament::PAIR_DOWN_DEVIATION_PERCENT` is used here. `League` needs this constant too (or it comes from `Event`). Move `PAIR_DOWN_DEVIATION_PERCENT` to `Event` as a default, allow subclasses to override.

### 1.2 Fix `SwissRound` validation
**File:** `app/models/swiss_round.rb`

- `uniqueness: { scope: :event_id }` → `uniqueness: { scope: :event_id, message: ... }`
- This validation ensures a SwissRound's number is unique per event (not globally). The existing index on `(number, round_id)` doesn't cover this; the validation is correct in intent but the scope should be documented. Or add a database unique index: `event_id + number` for SwissRounds.

### 1.3 Add default `advance_tournament!` to `Round`
**File:** `app/models/round.rb`

- Add `def advance_tournament!; end` (no-op default). Subclasses override. Prevents `NoMethodError` if a new Round type is created without implementing it.

### 1.4 Create `Room` model
**File:** `app/models/room.rb` (new)

```ruby
class Room < ApplicationRecord
  belongs_to :event
end
```

- Add `has_many :rooms, dependent: :destroy` to `Event` if not already present.

### 1.5 Rename old view directories
```
app/views/tournament_participants/         → app/views/event_participants/
app/views/organizer/tournament_participants/ → app/views/organizer/event_participants/
```

Inside the templates, rename partials:
- `_tournament_participant.html.erb` → `_event_participant.html.erb`
- Update all `render` calls that reference the old partial name.
- Search templates for any `@tournament_participants` / `@event_participant` locals and normalize.

### 1.6 Fix the flunking test
**File:** `test/jobs/tournaments/start_single_elimination_round_job_test.rb`

- Remove the `flunk` line.
- Add fixture: create Swiss round fixtures for `standard_tournament` (16 players = 2 Swiss rounds).
- Seed rounds in `test/fixtures/rounds.yml` with `type: SwissRound`.
- Ensure the test creates the Swiss rounds first, then verifies single-elimination round creation.

### 1.7 Add League & Circuit fixtures
**Files:** `test/fixtures/leagues.yml`, `test/fixtures/circuits.yml`

- Add a `standard_league` fixture (type: League, state: registration_open).
- Add a `standard_circuit` fixture linked to `standard_organizer`.

---

## Phase 2 — Database Schema (Migrations)

### 2.1 Migration: League-specific fields on events
**Why:** Leagues need mode (scheduled vs pick-up), wager percentage, and league_score tracking.

```ruby
class AddLeagueFieldsToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :play_mode, :integer, default: 0, null: false  # enum: scheduled, pickup
    add_column :events, :wager_percentage, :decimal, precision: 5, scale: 2  # e.g. 5.00 = 5%
  end
end
```

- Add enum to `League`: `enum :play_mode, { scheduled: 0, pickup: 1 }`
- `wager_percentage` lives on `Event` (shared for future tournament use) but is only used by leagues currently.

### 2.2 Migration: Circuit association
```ruby
class AddCircuitToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_reference :tournaments, :circuit, type: :uuid, foreign_key: true, null: true
  end
end
```

- **Note:** `Tournament` already has `belongs_to :circuit, optional: true` in the model, but the DB column `circuit_id` doesn't exist yet (schema shows no such column). The model association is orphaned — this migration fixes it.

### 2.3 Migration: Circuit standings
```ruby
class CreateCircuitStandings < ActiveRecord::Migration[8.0]
  def change
    create_table :circuit_standings, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :circuit, null: false, type: :uuid, foreign_key: true
      t.references :player, null: false, type: :uuid, foreign_key: true
      t.decimal :points, precision: 10, scale: 2, default: 0.0, null: false
      t.integer :events_count, default: 0, null: false
      t.timestamps
    end

    add_index :circuit_standings, [:circuit_id, :player_id], unique: true
  end
end
```

### 2.4 Migration: Event finish position (for circuit scoring)
```ruby
class AddFinalPositionToEventParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :event_participants, :final_position, :integer
  end
end
```

- Populated when an event finishes. Used by the circuit scoring service.

### 2.5 Migration: League round tracking
```ruby
class AddLeagueFieldsToRounds < ActiveRecord::Migration[8.0]
  def change
    add_column :rounds, :is_play_round, :boolean, default: false
    add_column :rounds, :is_finals_round, :boolean, default: false
  end
end
```

- Distinguishes play-phase rounds from finals-phase rounds (which are SingleEliminationRounds).
- For **Scheduled Play**: multiple `is_play_round: true` rounds, each pairing all players.
- For **Pick-up Play**: a single `is_play_round: true` round where pods are created on-demand.

---

## Phase 3 — Point Wager Scoring System

> **Reusable module** — not tied to League. Could be opted into by Tournaments later.

### 3.1 Service: `Scoring::PointWager`
**File:** `app/services/scoring/point_wager.rb` (new)

Core logic:

```ruby
module Scoring
  class PointWager
    STARTING_POINTS = 1000

    def initialize(event)
      @event = event
      @wager_pct = event.wager_percentage || 0
    end

    # Calculate all league scores after any change (full recalc)
    def recalculate_all!
      regular_scores = compute_scores(direction: :forward)
      reverse_scores = compute_scores(direction: :reverse)

      @event.event_participants.playing.each do |ep|
        avg = ((regular_scores[ep.id] || STARTING_POINTS) +
               (reverse_scores[ep.id] || STARTING_POINTS)).fdiv(2)
        ep.update!(league_score: avg)
      end
    end

    private

    def compute_scores(direction:)
      results = @event.rounds.play_rounds.order(number: :asc)
      results = results.reverse if direction == :reverse

      scores = {}
      @event.event_participants.playing.each { |ep| scores[ep.id] = STARTING_POINTS }

      results.each do |round|
        round.pods.finished.each { |pod| apply_pod_result(pod, scores) }
      end

      scores
    end

    def apply_pod_result(pod, scores)
      participants = pod.event_participants
      return if participants.empty?

      # Determine winner(s) from pod results
      wins = participants.select { |ep| pod_results(ep, pod).any?(&:win?) }
      draws = participants.select { |ep| pod_results(ep, pod).any?(&:draw?) }

      if wins.size == 1
        # Single winner takes all wagers
        winner = wins.first
        pot = participants.sum { |ep| wager_amount(scores[ep.id]) }
        participants.each { |ep| scores[ep.id] -= wager_amount(scores[ep.id]) }
        scores[winner.id] += pot
      elsif draws.size == participants.size
        # All draw — split evenly
        pot = participants.sum { |ep| wager_amount(scores[ep.id]) }
        per_person = pot.fdiv(participants.size)
        participants.each { |ep| scores[ep.id] = per_person }
      else
        # Partial draws / complex — split among non-losers
        # TODO: define exact rules
      end
    end

    def wager_amount(current_points)
      (current_points * @wager_pct / 100).round(2)
    end
  end
end
```

### 3.2 Migration: league_score on event_participants
```ruby
class AddLeagueScoreToEventParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :event_participants, :league_score, :decimal, precision: 10, scale: 2, default: 1000.0
  end
end
```

### 3.3 Hook: Recalculate after result submission
**File:** `app/jobs/events/submit_result_job.rb` (modify)

After a result is submitted, if the event is a League in play state, trigger a recalc:

```ruby
# After creating/updating the Result:
if @round.event.is_a?(League) && @round.event.play?
  Scoring::PointWager.new(@round.event).recalculate_all!
end
```

### 3.4 Scope additions to Round
```ruby
scope :play_rounds, -> { where(is_play_round: true) }
scope :finals_rounds, -> { where(is_finals_round: true) }
```

### 3.5 Tests
**File:** `test/services/scoring/point_wager_test.rb` (new)

- Test starting points = 1000
- Test single winner takes pot
- Test draw splits evenly
- Test regular + reverse direction averaging
- Test with multiple rounds
- Test with varying pod sizes (3, 4, 5)

---

## Phase 4 — League Jobs & Pairing

### 4.1 Job: `Leagues::StartPlayRoundJob`
**File:** `app/jobs/leagues/start_play_round_job.rb` (new)

For **Scheduled Play** mode: creates a new play-phase round with pods for ALL participants (all players paired each round).

```ruby
module Leagues
  class StartPlayRoundJob < ApplicationJob
    def perform(league)
      league.rounds.create!(
        type: SwissRound,        # re-use SwissRound for pod creation/pairing
        number: league.rounds.size + 1,
        is_play_round: true
      )
    end
  end
end
```

The existing `SwissRound#create_pods` → `Tournaments::CreatePodsJob` handles pod generation and pairing. This works because:
- Pod size constants come from `event.class` (STI)
- Player sorting by rank_score works (for leagues, rank_score ≈ league_score after scoring integration)
- Pairing strategies (standard, spread) are generic

**Question:** Should League play rounds use a different pairing strategy? For scheduled play, "pair all players" is the goal — the existing `CreatePodsJob` does this. The Swiss pairing strategies add anti-rematch logic which is also desirable.

### 4.2 Job: `Leagues::CreatePickupPodJob`
**File:** `app/jobs/leagues/create_pickup_pod_job.rb` (new)

For **Pick-up Play** mode: creates a single pod with available players (not in an ongoing pod).

```ruby
module Leagues
  class CreatePickupPodJob < ApplicationJob
    def perform(league, size = league.class::PREFERRED_POD_SIZE)
      @league = league
      @size = size

      play_round = league.rounds.play_rounds.first ||
        league.rounds.create!(type: SwissRound, number: 1, is_play_round: true)

      available = available_players(play_round)
      return if available.size < @size

      pod = play_round.pods.create!(number: play_round.pods.size + 1, size: @size)

      selected = available.first(@size)
      selected.each { |ep| pod.candidates << ep }
      pod.sit_participants!
    end

    private

    def available_players(play_round)
      @league.event_participants.playing.reject do |ep|
        # Exclude players in pods that aren't finished yet
        ep.pods.joins(:round)
               .where(rounds: { event_id: @league.id })
               .where.not(pods: { results: { event_participant_id: ep.id } })
               .exists?
      end
    end
  end
end
```

### 4.3 Job: `Leagues::StartSingleEliminationRoundJob`
**File:** `app/jobs/leagues/start_single_elimination_round_job.rb` (new)

Ranks players by `league_score`, takes the top cut, and creates the first single-elimination round.

```ruby
module Leagues
  class StartSingleEliminationRoundJob < ApplicationJob
    def perform(league)
      # Calculate final standings
      Scoring::PointWager.new(league).recalculate_all!

      # Determine top cut
      ranked = league.event_participants.playing
        .order(league_score: :desc)
        .limit(top_cut_size(league))

      # Create first single elimination round
      league.rounds.create!(
        type: SingleEliminationRound,
        number: league.rounds.size + 1,
        is_finals_round: true
      )
    end

    private

    def top_cut_size(league)
      # Use tournament-style thresholds or league-specific config
      participant_count = league.event_participants.playing.size
      # For now, mirror Tournament::PLAYERS_ROUNDS_THRESHOLDS logic
      # TODO: make configurable per league
    end
  end
end
```

### 4.4 Job: `Leagues::FinishLeagueJob`
**File:** `app/jobs/leagues/finish_league_job.rb` (new)

Sets final positions on all event_participants.

```ruby
module Leagues
  class FinishLeagueJob < ApplicationJob
    def perform(league)
      # Final score recalculation
      Scoring::PointWager.new(league).recalculate_all!

      # Set final positions
      ranked = league.event_participants.playing.order(league_score: :desc)
      ranked.each_with_index do |ep, index|
        ep.update!(final_position: index + 1)
      end

      # Update circuit standings if league belongs to a circuit
      # (Phase 6 concern, but hook here)
    end
  end
end
```

### 4.5 Update `League` model
**File:** `app/models/league.rb`

- Fix `Leagues::StartFinalsRoundJob` → `Leagues::StartSingleEliminationRoundJob` in `perform_state_based_actions`
- Add `enum :play_mode, { scheduled: 0, pickup: 1 }`
- Add `validates :wager_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true`
- Add `has_many :circuit_standings` if leagues can belong to circuits (design decision)

### 4.6 Update `EventParticipant` for league scoring
**File:** `app/models/event_participant.rb`

- Add `delegate :league_score, to: :...` or use the new `league_score` column directly.
- Add `rank_by_score` method that uses `league_score` for leagues, `rank_score` for tournaments.

```ruby
def rank_score
  return league_score if event.is_a?(League)
  super  # existing classic scoring
end
```

### 4.7 Tests
**Files:**
- `test/jobs/leagues/start_play_round_job_test.rb`
- `test/jobs/leagues/create_pickup_pod_job_test.rb`
- `test/jobs/leagues/start_single_elimination_round_job_test.rb`
- `test/jobs/leagues/finish_league_job_test.rb`

---

## Phase 5 — League Controllers, Routes & Views

### 5.1 Routes
**File:** `config/routes.rb`

```ruby
resources :leagues, only: %i[index show] do
  resources :rounds do
    resources :pods
  end

  resources :event_participants do
    collection do
      get "me"
    end
  end
end

namespace :organizer do
  resources :leagues do
    resources :infractions, only: %i[new create]
    resources :event_participants do
      resources :infractions, only: %i[index destroy]
    end
    resources :rounds do
      resources :seatings, only: [] do
        patch :swap, on: :collection
      end
      resources :pods do
        resources :results
        resources :infractions, only: %i[new create]
      end
    end

    # Pick-up play specific
    post :create_pickup_pod, on: :member
  end

  resources :circuits do
    resources :tournaments, only: %i[new create]  # add tournament to circuit
  end
end
```

### 5.2 Public Controllers
**Files:** `app/controllers/leagues_controller.rb`, `app/controllers/organizer/leagues_controller.rb`

Mirror `tournaments_controller.rb` and `organizer/tournaments_controller.rb` patterns:

```ruby
class LeaguesController < ApplicationController
  skip_before_action :require_authentication

  def index
    scope = League.with_attached_cover.where.not(state: %i[draft canceled]).preload(:rounds)
    # ... same filter logic as TournamentsController
  end

  def show
    @league = League.preload(rounds: :pods, event_participants: { player: :user }).find(params[:id])
  end
end
```

**Organizer controller** follows the same CRUD pattern as `Organizer::TournamentsController`, with:
- `league_params` including `play_mode`, `wager_percentage`
- State advancement logic
- `create_pickup_pod` action for pick-up play

### 5.3 Circuit Controller
**File:** `app/controllers/organizer/circuits_controller.rb` (new)

```ruby
module Organizer
  class CircuitsController < OrganizerController
    def index
      @circuits = Circuit.for_organizer(current_organizer).preload(:tournaments)
    end

    def show
      @circuit = Circuit.for_organizer(current_organizer).find(params[:id])
      @standings = CircuitStandings.for_circuit(@circuit).ranked
    end

    def new
      @circuit = Circuit.new(event_organizer: current_organizer)
    end

    def create
      @circuit = Circuit.create(circuit_params.merge(event_organizer: current_organizer))
      redirect_to [:organizer, @circuit]
    end

    def update
      # ...
    end
  end
end
```

### 5.4 Views
**Directories to create:**

```
app/views/leagues/
  index.html.erb
  show.html.erb
  _league.html.erb          # partial (mirror _tournament.html.erb)
  _league_detailed_info.html.erb

app/views/organizer/leagues/
  index.html.erb
  show.html.erb
  edit.html.erb
  new.html.erb
  _form.html.erb

app/views/organizer/circuits/
  index.html.erb
  show.html.erb
  new.html.erb
  edit.html.erb
  _form.html.erb
  _circuit.html.erb
  _standings.html.erb
```

### 5.5 Shared Event Components
Consider extracting shared UI into a `Event` ViewComponent or partials:
- `app/views/shared/_event_card.html.erb` — used by both tournaments and leagues index
- `app/views/shared/_event_header.html.erb` — cover, name, dates, location
- `app/views/shared/_event_participants_table.html.erb`

---

## Phase 6 — Circuit Scoring Service

### 6.1 Model: `CircuitStanding`
**File:** `app/models/circuit_standing.rb` (new)

```ruby
class CircuitStanding < ApplicationRecord
  belongs_to :circuit
  belongs_to :player

  scope :ranked, -> { order(points: :desc) }
  scope :for_circuit, ->(circuit) { where(circuit: circuit) }
end
```

### 6.2 Update `Circuit` model
**File:** `app/models/circuit.rb`

```ruby
class Circuit < ApplicationRecord
  has_many :tournaments, dependent: :nullify
  has_many :circuit_standings, dependent: :destroy
  belongs_to :event_organizer

  scope :for_organizer, ->(organizer) { where(event_organizer: organizer) }

  def standings
    circuit_standings.ranked
  end

  def update_standings!(tournament = nil)
    if tournament
      Circuits::UpdateStandingsJob.perform_now(self, tournament)
    else
      tournaments.finished.each do |t|
        Circuits::UpdateStandingsJob.perform_now(self, t)
      end
    end
  end
end
```

### 6.3 Service: `Circuits::CalculatePoints`
**File:** `app/services/circuits/calculate_points.rb` (new)

```ruby
module Circuits
  class CalculatePoints
    # Points awarded based on final position relative to event size
    # E.g., 1st place in 16-player event = 16 points, 2nd = 15, etc.
    # Or use a more nuanced scale.

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

        # Position-based points: higher placement = more points
        # 1st in 20-player event = 20pts, 20th = 1pt
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
**File:** `app/jobs/circuits/update_standings_job.rb` (new)

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
**File:** `app/jobs/tournaments/finish_tournament_job.rb` (modify)

```ruby
def perform(tournament)
  return unless tournament.circuit

  Circuits::UpdateStandingsJob.perform_now(tournament.circuit, tournament)
end
```

### 6.6 Tests
**Files:**
- `test/models/circuit_test.rb`
- `test/models/circuit_standing_test.rb`
- `test/services/circuits/calculate_points_test.rb`
- `test/jobs/circuits/update_standings_job_test.rb`

---

## Phase 7 — Polish & Cross-cutting Concerns

### 7.1 Event index page (unified listing)
- `GET /events` showing both tournaments and leagues
- Filter by type, organizer, date range
- `app/controllers/events_controller.rb`

### 7.2 Organizer dashboard
- Show all events (tournaments + leagues) + circuits in one view
- Quick actions: create tournament, create league, create circuit

### 7.3 League-specific view helpers
- Standings table (sorted by league_score)
- Play mode indicator (Scheduled vs Pick-up)
- Pick-up pod creation button (for organizers in pick-up mode)
- Wager percentage display

### 7.4 Circuit-specific view helpers
- Standings leaderboard
- Tournament results history
- Points breakdown per tournament

### 7.5 Update `Tournament` model
- Remove `has_one :circuit, through: ...` if it exists (it should be `belongs_to :circuit`)
- Ensure `Tournament` uses `event.class` for all constants that `Event` defines

### 7.6 Migration: Backfill `circuit_id` on tournaments
If `circuit_id` column doesn't exist on the `events` table (since tournaments are STI), add it there:

```ruby
class AddCircuitIdToEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :events, :circuit, type: :uuid, foreign_key: true, null: true
  end
end
```

Then update `Tournament` to remove the redundant `belongs_to :circuit` (it inherits from `Event`).

### 7.7 Rubocop & code quality
- Run `bin/rubocop` and fix any new offenses
- Run `bin/brakeman` for security review

### 7.8 System tests
- Add system tests for league creation flow
- Add system tests for circuit creation and standings display
- Add system tests for pick-up pod creation

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

## Open Design Decisions

1. **League top cut size** — Should leagues mirror tournament thresholds or have their own? Configurable per-league?
2. **Point wager partial draws** — What happens when a pod has a mix of wins and draws (not all participants draw)? Need exact rule.
3. **Circuit points formula** — Simple `total - position + 1` or a logarithmic/weighted scale? Should it be configurable?
4. **Can leagues belong to circuits?** Currently only tournaments belong to circuits. If leagues should also feed into circuit standings, `Event` needs `belongs_to :circuit`.
5. **Pick-up play: concurrent pods** — Multiple pods can run simultaneously. How does the UI show ongoing pods and available players?
6. **Wager percentage: configurable per-league or global?** The migration puts it on `events`, making it per-event.
