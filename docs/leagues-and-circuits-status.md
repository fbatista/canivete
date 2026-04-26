# Leagues & Circuits Refactoring Status

> **Date:** 2026-04-25
> **Goal:** Add leagues and circuits, refactor tournaments to extend from a shared Event base (STI).

---

## What's Done

### Database / Schema
- **`events` table** created via STI migration (`rename_tournaments_to_events`) with `type` column defaulting to `"Tournament"`
- All foreign key renames done: `tournament_id` → `event_id`, `tournament_participants_count` → `event_participants_count`, etc.
- **`rooms` table** exists (belongs to event)

### Models
- **`Event < ApplicationRecord`** — STI base class with:
  - Core fields: `name`, `slug`, `start_time`, `end_time`, `address`, `location` (PostGIS), `price`, `currency`
  - State machine (generic `available_states` / `perform_state_based_actions`)
  - `participants_range` with min/max helpers
  - `cover` attachment
  - Geocoding job
  - Scopes: `for_organizer`, `past`, `upcoming`, `for_player`
- **`Tournament < Event`** — All original tournament logic preserved (Swiss rounds, thresholds, scoring, single-elimination)
- **`League < Event`** — State machine defined: `draft → registration_open → registration_closed → play → finals → finished/canceled`
- **`Circuit < ApplicationRecord`** — `has_many :tournaments`, `belongs_to :event_organizer`
- **`EventOrganizer`** — `has_many :events`, `has_many :circuits`, currency enum
- **`EventParticipant`** — Renamed, references `event` instead of `tournament`, uses STI via `event.class` for constants
- **`Round`** — References `event` instead of `tournament`
- **`SwissRound` / `SingleEliminationRound`** — Still reference `tournament` via STI

### Tests
- **80 tests, 1 failure** — Only the `StartSingleEliminationRoundJobTest` has a `flunk` placeholder
  (`TODO: add swiss rounds to standard_tournament fixture`)

---

## What's Missing / Broken

### 1. League Jobs don't exist
`League#perform_state_based_actions` calls these jobs that are **not created yet**:
- `Leagues::StartPlayRoundJob`
- `Leagues::StartFinalsRoundJob`
- `Leagues::FinishLeagueJob`

### 2. No League/Circuit controllers or routes
- No `app/controllers/leagues_controller.rb`
- No `app/controllers/circuits_controller.rb`
- No `app/controllers/organizer/leagues_controller.rb`
- No `app/controllers/organizer/circuits_controller.rb`
- Routes reference only `tournaments`, no `events`, `leagues`, or `circuits`

### 3. No League/Circuit views
- No `app/views/leagues/` directory
- No `app/views/circuits/` directory
- No `app/views/organizer/leagues/` or `app/views/organizer/circuits/`

### 4. No tests for League or Circuit
- No `test/models/league_test.rb`
- No `test/models/circuit_test.rb`
- No fixtures for leagues or circuits

### 5. Old view directory names
- `app/views/tournament_participants/` should be `app/views/event_participants/`
- `app/views/organizer/tournament_participants/` should be `app/views/organizer/event_participants/`
- Templates still named `_tournament_participant.html.erb`

### 6. Pod model still references `tournament`
```ruby
# app/models/pod.rb
has_one :tournament, through: :round
```
Should be `has_one :event, through: :round`. Methods like `swap_suitable_by_rank_for?` call
`tournament.class::PAIR_DOWN_DEVIATION_PERCENT`.

### 7. SwissRound validation references wrong column
```ruby
# app/models/swiss_round.rb
uniqueness: { scope: :event_id }  # should be scope: :number, via round table
```

### 8. Round base class missing `advance_tournament!`
Called in `after_update :round_finished` but only defined in subclasses (`SwissRound`, `SingleEliminationRound`).
The base `Round` class has no default implementation.

### 9. `Room` model doesn't exist
The `rooms` table exists in the schema but there's no `app/models/room.rb`.

### 10. Single test flunk
`StartSingleEliminationRoundJobTest` line 11 has a hardcoded `flunk` that needs fixture setup.

---

## Some important considerations

Leagues should use a different point system. Instead of the classic points per win, draw, loss (0), we're going to use a point-wager system. Which means that:
- League rounds work differently
  - League rounds can have rounds added iteratively or all at once, depending on the user's needs.
  - This means that a League can have 2 modes: Pick-up Play or Scheduled Play
  - For Schedule Play, there can be multiple rounds during the play phase and each round will pair all players.
  - For Pick-up Play, there is only a single play round, and pods are created and played one at a time (tecnically multiple pods can be ongoing in parallel, but a single player can only be in an ongoing pod at a time)
  - The point wager system should make all players start with 1000 points and after each pod is completed, the points for the participating players are adjusted (each player wages a percentage of their points in the pod, and a draw splits it evenly by the number of participants, while a win awards them all to the winner)
  - However, because this point wager has a flaw where a playing a great player at the start of the league is different from playing them at the end, we need to adjust the points further. So we calculate the "regular direction score" and the "reverse direction score", sum them and divide by 2. This makes it so that playing against a good player at the start vs at the end of the league is the same.
  - This point wager system should be a separate module from the leagues intrinsics, because at some point we might want to make the point system configurable for regular tournaments and opt between the standard method and point wager.
  - The final rounds of a league happen exactly the same way as for regular tournaments, we rank the players by score and take the top cut and build a single elimination stage with them. So we need to change that Leagues::StartFinalsRoundJob to Leagues::StartSingleEliminationRoundJob.

Circuits are simply a way to take player's results from tournaments and award points based on their final position in the event vs event size and then keep a leaderboard. 

## Summary

The **STI refactoring foundation is solid** — the database is migrated, `Event` is the base class,
`Tournament < Event` works, and `League < Event` has its state machine defined. The main gaps are:

1. **League infrastructure** (jobs, controllers, views, routes, tests) — all missing
2. **Circuit infrastructure** (controllers, views, routes, tests) — all missing
3. **Cleanup** — old `tournament_participant` view names, `Pod#tournament` reference, missing `Room` model
4. **1 failing test** — easy fix (add swiss round fixtures)
