# frozen_string_literal: true

class CreateCircuitStandings < ActiveRecord::Migration[8.0]
  def change
    create_table :circuit_standings, id: :uuid do |t|
      t.references :circuit, null: false, type: :uuid, foreign_key: true
      t.references :player, null: false, type: :uuid, foreign_key: true
      t.decimal :points, precision: 10, scale: 2, default: 0.0, null: false
      t.integer :events_count, default: 0, null: false

      t.timestamps
    end

    add_index :circuit_standings, [:circuit_id, :player_id], unique: true
  end
end
