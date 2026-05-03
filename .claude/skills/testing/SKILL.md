---
name: testing
description: Write and maintain Minitest tests with fixtures, SimpleCov coverage, Capybara system tests, and WebMock
license: MIT
---

## What I do
- Write model, service, controller, and job tests following project conventions
- Manage fixtures in `test/fixtures/*.yml` with STI type handling
- Write system tests using Capybara + Selenium (Firefox) with WebMock
- Maintain SimpleCov coverage reporting with parallel worker support

## When to use me
- Adding new features that need test coverage
- Fixing tests broken by refactoring
- Writing system tests for interactive flows
- Debugging test failures in parallel worker runs

## Project Conventions

### Test Structure
```
test/
  models/          — unit tests for models
  services/        — unit tests for service objects
  controllers/     — controller tests (JSON + request)
  jobs/            — background job tests
  system/          — Capybara system tests
  integration/     — multi-controller flow tests
  fixtures/        — YAML fixtures
  test_helper.rb   — SimpleCov + parallel workers + fixtures :all
```

### test_helper.rb Patterns
- `fixtures :all` — always load all fixtures
- `parallelize(workers: :number_of_processors)` — parallel test execution
- `Event.reset_counters` in `setup` block — counter cache consistency
- `WebMock.disable_net_connect!(allow_localhost: true)` — block external HTTP
- SimpleCov with worker-scoped `command_name` for parallel coverage merging

### Model Tests
- Test validations with `assert_not` / `assert` patterns
- Test associations with `assert_not_nil` / `assert_equal`
- Test scopes with `assert_equal expected, Model.scope`
- Test STI with `type: "Tournament"` in fixtures
- Use `fixtures :all` then reference by key: `players(:player_one)`

### Fixture Patterns
- STI models require `type: "Tournament"` field
- Counter caches set explicitly: `event_participants_count: 4`
- Enum values use integer: `state: 3` (not `:swiss`)
- Time values use ERB: `<%= 1.week.from_now %>`
- Fixtures are named for semantic access: `standard_tournament`, `small_tournament_swiss`

### System Tests
- Base class: `ApplicationSystemTestCase` → Selenium/Firefox, 1920x1080
- Fill forms: `fill_in "session_email_address", with: "user@example.com"`
- Click: `click_button "Sign in"`, `click_link "Logout"`
- Assertions: `assert_current_path`, `assert_text`, `assert_no_text`, `assert_field`
- Use private helper methods for repeated auth: `sign_in_as(user)`
- Test redirects: unauthenticated user → `assert_current_path new_session_path`

### Service Tests
- Test `#method!` (bang) methods with `assert_not_raise`
- Test state changes by reloading or checking DB directly
- Use fixtures for setup data
- Test edge cases (empty collections, nil values, boundary conditions)

### Coverage
- `SimpleCov.start "rails"` in test_helper.rb
- Filter out `/bin/`, `/db/`, `/test/` directories
- Coverage files in `coverage/` directory
- Run `bin/rails test` to regenerate

## Key Files
- `test/test_helper.rb` — Test setup, SimpleCov, fixtures, parallel workers
- `test/application_system_test_case.rb` — System test base (Selenium/Firefox)
- `test/fixtures/events.yml` — Example fixture file with STI + enums + counter caches
- `test/system/authentication_test.rb` — Example system test with sign-in flow
- `test/services/scoring/point_wager_test.rb` — Example service test
