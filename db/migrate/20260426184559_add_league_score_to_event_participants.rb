# frozen_string_literal: true

class AddLeagueScoreToEventParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :event_participants, :league_score, :decimal, precision: 10, scale: 2, default: 1000.0
  end
end
