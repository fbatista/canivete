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

This is a **Rails 8** tournament management system ("Canivete") for organizing competitive gaming tournaments with Swiss and single-elimination formats.

### Core Domain Models

- **Tournament**: Central entity managing tournament lifecycle (draft → registration_open → registration_closed → swiss → single_elimination → finished)
- **Round**: Supports both SwissRound and SingleEliminationRound with complex pairing algorithms
- **Pod**: Tournament matches/tables with 3-5 players per pod
- **TournamentParticipant**: Player registration and tracking within tournaments
- **Result**: Match outcomes with sophisticated scoring system
- **Infraction**: Tournament violations and penalties

### Key Business Logic

- **Swiss System**: Uses spread matching and forced pairing strategies in `app/services/tournaments/strategies/`
- **Tournament Structure**: Dynamic round generation based on player count thresholds (see `Tournament::PLAYERS_ROUNDS_THRESHOLDS`)
- **Scoring**: 7 points per win, 1 point per draw, 0 points per loss
- **Pod Sizing**: Prefers 4-player pods, allows 3-5 players with sophisticated balancing

### Authentication & Authorization

- Rails 8 built-in authentication (removed Devise)
- Session-based authentication via `Session` model
- Password reset functionality with `PasswordsMailer`
- Organizer namespace for tournament management functions

### Frontend Stack

- **Hotwire**: Turbo + Stimulus for reactive UI
- **Tailwind CSS 4**: With Flowbite components
- **ViewComponents**: Component-based architecture in views
- **Importmap**: JavaScript module management

### Background Jobs

Uses Solid Queue for job processing:
- Tournament state transitions (`Tournaments::StartSwissRoundJob`, etc.)
- Pod creation and player matching
- Result submission and tournament progression
- Address geocoding

### Database

- **PostgreSQL** with PostGIS for location data
- **UUID primary keys** across all models
- **Solid Cache**, **Solid Queue**, and **Solid Cable** for Rails infrastructure

### Testing

- Minitest with system tests using Capybara/Selenium
- Fixtures in `test/fixtures/` with sample tournament data
- Test images for cover photo uploads in `test/fixtures/files/`

## Code Conventions

- Ruby style follows Rails Omakase via rubocop-rails-omakase
- Frozen string literals enforced
- Strong parameters validation in controllers
- Service objects in `app/services/` for complex business logic
- Concern-based organization for shared behavior
- ActiveJob for background processing

## Key Files to Understand

- `app/models/tournament.rb`: Core tournament logic and state machine
- `config/routes.rb`: Nested resource structure with organizer namespace  
- `app/services/tournaments/strategies/`: Swiss pairing algorithms
- `app/controllers/concerns/authentication.rb`: Auth implementation