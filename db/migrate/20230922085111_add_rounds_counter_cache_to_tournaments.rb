# frozen_string_literal: true

class AddRoundsCounterCacheToTournaments < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :rounds_count, :integer, null: false, default: 0
    add_column :tournaments, :tournament_participants_count, :integer, null: false, default: 0
  end
end
