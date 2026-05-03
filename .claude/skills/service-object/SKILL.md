---
name: service-object
description: Create service objects in app/services/ using module namespaces for encapsulation
license: MIT
---

## What I do
- Design service objects with a clear public interface
- Organize services under module namespaces matching their domain
- Write service tests in corresponding `test/services/` directories

## When to use me
- Extracting complex logic from models or controllers
- Implementing multi-step business processes
- Creating reusable domain operations
- Adding background job logic that doesn't belong in the job class

## When NOT to use a service object
- Simple one-liner model methods (keep in the model)
- Controllers that only render views
- Callbacks that are single-purpose

## Project Conventions

### File Structure
```
app/services/
  tournaments/
    player_sorter.rb
    uneven_pod_generator.rb
    strategies/
      swiss_matcher.rb
      spread_matcher.rb
  scoring/
    point_wager.rb
  circuits/
    calculate_points.rb
```

### Service Object Pattern
```ruby
# frozen_string_literal: true

module Namespace
  class ClassName
    def initialize(dependency_one, dependency_two)
      @dependency_one = dependency_one
      @dependency_two = dependency_two
    end

    def public_method!(arg1, arg2:)
      # Public API — bang method for operations with side effects
    end

    private

    attr_reader :dependency_one, :dependency_two

    def helper_method(arg)
      # Private implementation
    end
  end
end
```

### Naming
- Class: PascalCase, verb-noun (e.g., `CalculatePoints`, `UnevenPodGenerator`)
- Method: `#method!` for mutating operations, `#method` for read-only
- Module: snake_case matching folder name (e.g., `module Tournaments`, `module Scoring`)

### Testing Services
- Place in `test/services/namespaced/` matching directory structure
- Test public API with clear assertions
- Use fixtures for setup data
- Test bang methods: `assert_not_raise { service.public_method! }`
- Test state changes by checking database or reloaded objects

## Key Files
- `app/services/scoring/point_wager.rb` — Example: full recalculation, multiple private helpers
- `app/services/circuits/calculate_points.rb` — Example: iteration with find_or_initialize
- `app/services/tournaments/uneven_pod_generator.rb` — Example: calculate + build pattern
