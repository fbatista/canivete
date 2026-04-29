# frozen_string_literal: true

class AddLeagueFieldsToRounds < ActiveRecord::Migration[8.0]
  def change
    add_column :rounds, :is_play_round, :boolean, default: false, null: false
    add_column :rounds, :is_finals_round, :boolean, default: false, null: false
  end
end
