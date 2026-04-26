# frozen_string_literal: true

class AddTournamentOrganizerToTournament < ActiveRecord::Migration[7.0]
  def change
    add_belongs_to :tournaments, :event_organizer, type: :uuid, index: true
  end
end
