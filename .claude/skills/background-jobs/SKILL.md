---
name: background-jobs
description: Create and manage Solid Queue background jobs with perform_now vs perform_later patterns
license: MIT
---

## What I do
- Create ActiveJob classes in `app/jobs/` with module namespaces
- Choose between `perform_now` (synchronous) and `perform_later` (async)
- Structure jobs for reliability with discard_on handlers
- Write job tests in `test/jobs/`

## When to use me
- Adding new background jobs for state transitions
- Extracting expensive operations from request cycle
- Chaining jobs that depend on each other
- Adding retry or discard logic

## When NOT to use a job
- Simple operations that complete in <100ms
- Operations that must run in the same transaction as the caller
- One-off scripts (use rake tasks instead)

## Project Conventions

### File Structure
```
app/jobs/
  application_job.rb
  tournaments/
    start_swiss_round_job.rb
    start_single_elimination_round_job.rb
    finish_round_job.rb
    finish_tournament_job.rb
    create_pods_job.rb
    create_single_elimination_pods_job.rb
  leagues/
    start_play_round_job.rb
    start_finals_round_job.rb
    finish_league_job.rb
    create_pickup_pod_job.rb
  events/
    geocode_job.rb
    submit_result_job.rb
  circuits/
    update_standings_job.rb
```

### Job Skeleton
```ruby
# frozen_string_literal: true

module Namespace
  class DescriptionJob < ApplicationJob
    discard_on ActiveJob::DeserializationError

    def perform(record)
      # Job body
    end
  end
end
```

### perform_now vs perform_later
- **`perform_now`**: Synchronous, runs in the same thread, same transaction as caller
  - Used for: state transitions that must complete immediately, job chaining
  - Example: `Tournaments::StartSwissRoundJob.perform_now(event)` in `perform_state_based_actions`
- **`perform_later`**: Async, enqueued to Solid Queue, runs after request
  - Used for: non-blocking operations like geocoding
  - Example: `Events::GeocodeJob.perform_later(self)` in `after_save` callback

### Job Chaining Pattern
Jobs that trigger other jobs:
```ruby
# In a model or service:
def advance_tournament!
  return if last_round?
  Tournaments::StartSwissRoundJob.perform_now(event)
end
```

### State Machine Job Triggers
State changes in models trigger jobs via `perform_state_based_actions`:
- `:swiss` → `StartSwissRoundJob`
- `:single_elimination` → `StartSingleEliminationRoundJob`
- `:finished` → `FinishTournamentJob`
- `:play` (League) → `StartPlayRoundJob`
- `:finals` (League) → `StartFinalsRoundJob`

### ApplicationJob Base
```ruby
class ApplicationJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError
  # retry_on ActiveRecord::Deadlocked  — uncomment if needed
end
```

### Job Testing
```ruby
# test/jobs/namespace/job_name_test.rb
require "test_helper"

class Namespace::JobNameTest < ActiveJob::TestCase
  test "job performs expected action" do
    record = create :factory_name  # if using factory_bot
    # or use fixtures
    assert_difference "Model.count", 1 do
      Namespace::JobName.perform_now(record)
    end
  end
end
```

## Key Files
- `app/jobs/application_job.rb` — Base job with discard_on
- `app/jobs/tournaments/start_swiss_round_job.rb` — Minimal job example
- `app/models/swiss_round.rb:33` — Example: `perform_now` chaining from model
- `app/models/event.rb:32` — Example: state-change triggers `perform_state_based_actions`
