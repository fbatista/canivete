# frozen_string_literal: true

class AddTournamentOrganizerToTournament < ActiveRecord::Migration[7.0]
  def change
    add_belongs_to :tournaments, :tournament_organizer
  end
end
