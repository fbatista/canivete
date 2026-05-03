# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- **Start development server**: `bin/dev` (uses Procfile.dev to run Rails server and Tailwind CSS watcher)
- **Rails console**: `bin/rails console`
- **Database commands**: 
  - `bin/rails db:migrate`
  - `bin/rails db:seed`
  - `bin/rails db:reset`
- **Testing**: 
  - `bin/rails test` (for unit tests)
  - `bin/rails test:system` (for system tests)
- **Code quality**:
  - `bin/rubocop` (Ruby linting with Rails Omakase configuration)
  - `bin/brakeman` (security analysis)
- **Asset compilation**: `bin/rails tailwindcss:build`

## Architecture Overview

This is a **Rails 8** tournament management system ("Canivete") for organizing competitive gaming tournaments (Magic: The Gathering) with Swiss and single-elimination formats. The app also supports **Leagues** (pickup play with wagers) and **Circuits** (multi-event point standings).

### Domain Hierarchy

```
Event (abstract base)
├── Tournament (Swiss + single-elimination)
└── League (pickup play with wagers)
```

### Core Domain Models

- **Event**: Base class for Tournament/League; handles rounds, event_participants, infractions, rooms
- **Tournament**: Extends Event with Swiss + single-elimination tournament logic
- **League**: Extends Event with play/finals states, scheduled or pickup play modes, wagers
- **Circuit**: Container for multiple events with player standings
- **EventParticipant**: Player's registration and tracking within an event (Tournament or League)
- **Player**: A user's gaming identity (linked to User, has a unique key)
- **Round**: Supports SwissRound and SingleEliminationRound with complex pairing algorithms
- **Pod**: Tournament matches/tables with 3-5 players per pod
- **Seating**: Links event_participants to pods with ordering
- **Result**: Match outcomes (Win, Draw, Loss, Eliminated, Advance, Penalty)
- **Infraction**: Tournament violations and penalties (MTG-style)
- **CircuitStanding**: Per-player standings within a circuit
- **EventOrganizer**: Organizer account linked to a User
- **Room**: Physical room assignment for events

### Key Business Logic

- **Swiss System**: Uses spread matching and forced pairing strategies in `app/services/tournaments/strategies/`
- **Tournament Structure**: Dynamic round generation based on player count thresholds (see `Tournament::PLAYERS_ROUNDS_THRESHOLDS`)
- **Scoring**: 7 points per win, 1 point per draw, 0 points per loss
- **Pod Sizing**: Prefers 4-player pods, allows 3-5 players with sophisticated balancing
- **Ghost Opponents**: Handles byes for Swiss rounds by injecting Ghost objects into opponent calculations
- **Spread Matching**: Serpentine pod assignment for spread-based rounds
- **Forced Pairing**: Rank-diff-based pairing with swap logic for forced rounds

### Tournament State Machine

```
draft → registration_open → registration_closed → swiss → single_elimination → finished
```

States can transition to `canceled` from most states. Defined in `Tournament::TRANSITIONS`.

### League State Machine

```
draft → registration_open → registration_closed → play → finals → finished
```

States can transition to `canceled` from most states. Play mode can be `scheduled` or `pickup`.

### Circuit System

- Circuits contain multiple events (Tournaments/Leagues)
- After each event, `Circuits::CalculatePoints` awards circuit points: `(total_participants - final_position + 1)`
- `CircuitStanding` tracks per-player accumulated points and events count
- Circuits have `ranked` scope (ordered by points descending)

### Infraction System (MTG-style)

Infractions have a hierarchical enum structure:
- **kind**: `game_play_errors` (200), `tournament_errors` (300), `unsporting_conduct` (400)
- **category**: Subcategories must match their parent kind (e.g., `missed_trigger` 201 requires `game_play_errors` 200)
- **penalty**: `warning` (0), `game_loss` (1), `match_loss` (2), `disqualification` (3), `priority_skip` (4)
- Auto-creates associated `Penalty` results for match_loss/disqualification infractions
- Each infraction can reference an `event` or a `pod` (or both)

### Scoring & Wagers

- **Match Points**: `draws * 1 + wins * 7`
- **Rank Score**: Hierarchical tiebreaker combining advancements, match points, match win percentage, opponent average match points, opponent average match win percentage
- **League Scores (wagers)**: `Scoring::PointWager` starts all participants at 1000 points, calculates forward and reverse through rounds, and averages the two for the final `league_score`
- Wager percentage per event determines what portion of each player's score is at risk

### Authentication & Authorization

- Rails 8 built-in authentication (removed Devise)
- Session-based authentication via `Session` model
- Password reset functionality with `PasswordsMailer`
- `EventOrganizer` namespace for tournament management functions
- `Current` concern for request-scoped state

### Frontend Stack

- **Hotwire**: Turbo + Stimulus for reactive UI
- **Tailwind CSS 4**: With Flowbite components (@tailwindcss/forms, @tailwindcss/typography, @tailwindcss/container-queries)
- **Importmap**: JavaScript module management
- **Herb**: ERB template engine with JSX-like syntax support (includes `reactionview` gem for validation)
- **Phosphor Icons**: Icon library via CDN

### Background Jobs

Uses Solid Queue for job processing:
- **Tournaments**: `StartSwissRoundJob`, `StartSingleEliminationRoundJob`, `FinishTournamentJob`, `CreatePodsJob`, `CreateSingleEliminationPodsJob`, `FinishRoundJob`
- **Leagues**: `StartPlayRoundJob`, `StartFinalsRoundJob`, `FinishLeagueJob`, `CreatePickupPodJob`
- **Events**: `GeocodeJob`, `SubmitResultJob`
- **Circuits**: `UpdateStandingsJob`

### Database

- **PostgreSQL** with PostGIS for location data (activerecord-postgis-adapter)
- **UUID primary keys** across all models (pgcrypto `gen_random_uuid()`)
- **Solid Cache**, **Solid Queue**, and **Solid Cable** for Rails infrastructure
- **Kaminari** for pagination
- **pgcrypto** extension enabled (for `gen_random_uuid()`)

### Testing

- Minitest with system tests using Capybara/Selenium (Firefox)
- SimpleCov for coverage reporting with parallel worker support
- WebMock for HTTP stubbing in tests
- Fixtures in `test/fixtures/` with sample tournament data
- Service tests in `test/services/`
- Run with parallel workers: `bin/rails test` (uses `:number_of_processors` workers)

## Code Conventions

- Ruby style follows Rails Omakase via rubocop-rails-omakase
- Frozen string literals enforced (`# frozen_string_literal: true`)
- Strong parameters validation using `params.expect` (Rails 8 permit API)
- Service objects in `app/services/` with module namespaces
- Concern-based organization for shared behavior
- ActiveJob for background processing
- STI for Event types (Tournament, League) and Result types (Win, Draw, Loss, Eliminated, Advance, Penalty)
- Double-quoted strings (Style/StringLiterals)
- Explicit block forwarding (Naming/BlockForwarding: explicit)
- Hash syntax shorthand disabled (Style/HashSyntax: never)

## Rubocop Config Highlights

- Plugins: `rubocop-rails`, `rubocop-performance`, `rubocop-capybara`
- `Style/CollectionMethods`: prefer `map` over `collect`, `find` over `detect`, `reduce` over `inject`, `select` over `find_all`
- `Style/HashSyntax`: `EnforcedShorthandSyntax: never` (use `key: value` not `{key}`)
- `Style/NumericLiterals`: `MinDigits: 15` (underscore separators for large numbers)

## Routes Structure

```
GET  /                           → events#index
POST /registrations              → registrations#create
GET/POST /session                → sessions (create/destroy)
POST /passwords/:token           → passwords (reset)
GET  /tournaments                → tournaments#index/show
GET  /leagues                    → leagues#index/show
GET  /circuits                   → circuits#index/show
GET  /events                     → events#index

Organizer namespace (requires organizer auth):
GET/POST /organizer              → organizer/tournaments#index (root)
REST /organizer/tournaments      → CRUD + event_participants, infractions, rounds/pods/results/infractions/seatings
POST /organizer/leagues/:id/create_pickup_pod
REST /organizer/leagues          → CRUD + same nested resources
REST /organizer/circuits         → CRUD + nested tournaments (new/create)
```

## Key Files to Understand

- `app/models/event.rb`: Base class for Tournament/League, handles shared event logic
- `app/models/tournament.rb`: Swiss + single-elimination tournament logic
- `app/models/league.rb`: League/pickup play with wagers
- `app/models/event_participant.rb`: Player registration, scoring, rank calculations
- `app/models/infraction.rb`: MTG-style infraction system
- `app/models/result.rb`: STI for match outcomes
- `app/models/circuit.rb`: Multi-event standings container
- `config/routes.rb`: Nested resource structure with organizer namespace
- `app/services/tournaments/strategies/swiss_matcher.rb`: Swiss pairing with swaps
- `app/services/tournaments/strategies/spread_matcher.rb`: Serpentine spread matching
- `app/services/tournaments/uneven_pod_generator.rb`: 3-5 player pod generation
- `app/services/scoring/point_wager.rb`: League score/wager calculations
- `app/services/circuits/calculate_points.rb`: Circuit point awards
- `app/controllers/concerns/authentication.rb`: Auth implementation
- `app/controllers/application_controller.rb`: Base controller with Prosopite N+1 detection
