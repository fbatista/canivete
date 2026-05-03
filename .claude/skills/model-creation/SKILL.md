---
name: model-creation
description: Create and modify Rails models following project conventions for STI, enums, validations, counter caches, and scopes
license: MIT
---

## What I do
- Generate new models with `bin/rails g model`
- Set up STI hierarchies (Event → Tournament/League, Result → Win/Draw/Loss)
- Configure enum columns, counter caches, and associations
- Write validations using modern Rails 8 syntax (`{ presence: true }`)
- Add scopes and class methods

## When to use me
- Adding new domain models
- Adding STI children to existing hierarchies
- Modifying model associations or validations
- Adding enums or counter caches

## Project Conventions

### File Location
- Models: `app/models/<name>.rb`
- Concerns: `app/models/concerns/`
- STI children in same file or separate file

### Model Skeleton
```ruby
# frozen_string_literal: true

class ModelName < ApplicationRecord
  # Associations
  belongs_to :parent, optional: true
  has_many :children, dependent: :destroy

  # Enums
  enum :status, { draft: 0, active: 1 }, default: :draft

  # Validations (Rails 8 style)
  validates :field, { presence: true }
  validates :other, { uniqueness: { scope: :parent_id } }

  # Scopes
  scope :active, -> { where(status: :active) }

  # Callbacks (if needed)
  before_save :compute_slug
end
```

### STI (Single Table Inheritance)
- Base class: `Event < ApplicationRecord` (type column: `type`)
- Subclass: `Tournament < Event` (no explicit type needed if base defaults)
- Type column in schema: `t.string "type", default: "Tournament", null: false`
- Subclass files: `app/models/tournament.rb`, `app/models/league.rb`
- STI children inherit base associations; override as needed
- Fixtures require explicit `type: "Tournament"` field

### Enums
- Integer-backed: `enum :state, { draft: 0, open: 1 }, default: :draft`
- Prefixed enums: `enum :play_mode, { scheduled: 0, pickup: 1 }, prefix: true`
  - Generates `play_mode_scheduled?`, `play_mode_pickup?`, `play_mode_scheduled!`
  - Aliases: `alias pickup_play_mode? play_mode_pickup?`
- Enum validation via integer values in fixtures: `state: 3`

### Counter Caches
- Declare: `belongs_to :event, counter_cache: true`
- Schema needs integer column: `t.integer "event_participants_count", default: 0, null: false`
- Reset in fixtures: set explicitly (counter caches not auto-set from fixtures)
- Call `Event.reset_counters` in `test_helper.rb` setup block

### Validations (Rails 8)
- Hash-style: `validates :name, { presence: true }` — preferred over `validates :name, presence: true`
- With options: `validates :field, { uniqueness: { scope: :parent_id } }`
- Conditional: `validates :other, { numericality: { greater_than: 0 }, allow_blank: true }`
- Custom validations: `validate :must_match_kind_with_category`
- `with_options presence: true do ... end` for grouped presence

### Associations
- `belongs_to` with `optional: true` when foreign key is nullable
- `has_many ... dependent: :destroy` for ownership
- `has_many ... dependent: :nullify` for soft references
- `has_one ... dependent: :nullify` for one-to-one
- `through` associations: `has_many :players, through: :event_participants`
- Scoped associations: `has_many :results, -> { publishable }`

### Scopes
- Lambda scopes: `scope :ongoing, -> { where(state: %i[swiss single_elimination]) }`
- Order scopes: `scope :ranked, -> { order(points: :desc) }`
- Join scopes: `scope :for_organizer, ->(organizer) { where(event_organizer: organizer) }`
- Complex SQL scopes for existence checks
- Publishable scope pattern: `joins(:parent).where.not(parents: { finished_at: nil })`

### Callbacks
- Prefer `before_validation` over `before_save` when value computation is needed
- `after_update :action, if: -> { field_previously_changed? }` for change-triggered actions
- `before_save :reset_cache, if: -> { linked_previously_changed? }`
- Use `previously_changed?` instead of `was` for Rails 8 compatibility

### Active Record Patterns
- `attribute :field, :type` for typed attributes with defaults
- `normalizes :field, with: ->(e) { e.strip.downcase }` for normalization
- `find_or_initialize_by` for upsert patterns
- `find_or_create_by` for create-or-retrieve patterns
- `update_columns` for bypassing callbacks (use sparingly)

## Key Files
- `app/models/user.rb` — Example: STI-like setup, callbacks, normalization
- `app/models/event.rb` — Example: counter caches, STI base, scopes
- `app/models/infraction.rb` — Example: enum hierarchy, custom validations
- `app/models/league.rb` — Example: prefixed enums, aliased predicates
