# frozen_string_literal: true

class RenameTournamentsToEvents < ActiveRecord::Migration[8.0]
  def change
    rename_table :tournament_organizers, :event_organizers
    rename_column :tournament_participants, :tournament_id, :event_id
    rename_table :tournament_participants, :event_participants
    rename_column :tournaments, :tournament_organizer_id, :event_organizer_id
    rename_column :tournaments, :tournament_participants_count, :event_participants_count
    rename_table :tournaments, :events
    add_column :events, :type, :string, default: "Tournament", null: false
    rename_column :infractions, :tournament_id, :event_id
    rename_column :results, :tournament_participant_id, :event_participant_id
    rename_column :rooms, :tournament_id, :event_id
    rename_column :rounds, :tournament_id, :event_id
    rename_column :seatings, :tournament_participant_id, :event_participant_id
  end
end
