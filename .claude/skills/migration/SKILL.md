---
name: migration
description: Write database migrations for PostgreSQL with PostGIS, UUID primary keys, enums, and counter caches
license: MIT
---

## What I do
- Generate and write migrations following project conventions
- Add PostGIS geography columns, UUID columns, enum integer columns
- Create counter cache columns, composite unique indexes
- Write reversible migrations for schema modifications

## When to use me
- Adding new models or columns
- Modifying existing schemas (adding indexes, changing types)
- Adding PostGIS geography support
- Setting up counter caches

## Project Conventions

### Migration Generation
```bash
bin/rails g model ModelName field:type
bin/rails g migration AddFieldNameToModelName field:type
```

### Schema Conventions
- **Primary keys**: All tables use `id: :uuid, default: -> { "gen_random_uuid()" }`
- **Timestamps**: `created_at` and `updated_at` always present, `null: false`
- **Type columns**: STI uses `t.string "type", default: "ClassName", null: false`
- **Enum columns**: `t.integer "field", default: 0` — enum mapping done in model
- **Counter caches**: `t.integer "related_count", default: 0, null: false`

### Common Migration Patterns

#### Adding a Column
```ruby
class AddFieldNameToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :models, :field_name, :string, null: false
    add_index :models, :field_name
  end
end
```

#### Counter Cache Column
```ruby
def change
  add_column :events, :rounds_count, :integer, default: 0, null: false
  add_column :events, :event_participants_count, :integer, default: 0, null: false
end
```

#### PostGIS Geography Column
```ruby
def change
  add_column :events, :location, :geography, limit: { srid: 4326, type: "st_point", geographic: true }
  execute 'CREATE INDEX index_events_on_location ON events USING GIST (location)'
end
```

#### Composite Unique Index
```ruby
def change
  add_index :circuit_standings, [:circuit_id, :player_id], unique: true
  add_index :results, [:event_participant_id, :round_id], unique: true
  add_index :pods, [:number, :round_id], unique: true
end
```

#### Adding Foreign Key
```ruby
def change
  add_foreign_key :child_table, :parent_table, column: :parent_id
end
```

### Enabling Extensions
Schema-level (in schema.rb, not migrations):
```ruby
enable_extension "pgcrypto"
enable_extension "postgis"
```

### Schema.rb vs Migrations
- `db/schema.rb` is auto-generated, never edited directly
- Always use migrations to modify the database
- `bin/rails db:schema:load` uses schema.rb for fast database setup
- `bin/rails db:migrate` applies pending migrations

### UUID Configuration
- `gen_random_uuid()` requires pgcrypto extension (enabled in schema)
- Foreign keys to UUID columns work the same as integer FKs
- `find(params[:id])` works with UUIDs automatically

### Enum Migrations
- Store as integers in DB: `t.integer "state", default: 0, null: false`
- Model handles enum mapping: `enum :state, { draft: 0, open: 1 }`
- Migration sets default integer value, not symbol

### Indexing Strategy
- Foreign key columns: add index (most queries filter by FK)
- Composite unique indexes for business uniqueness
- GIST indexes for PostGIS geography columns
- Kaminari pagination doesn't need special indexes

## Key Files
- `db/schema.rb` — Reference for all current columns, types, indexes, foreign keys
- `bin/rails db:setup` — Creates DB, loads schema, seeds
- `bin/rails db:migrate` — Applies pending migrations
