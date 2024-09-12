# frozen_string_literal: true

class AddDroppedToTournamentParticipant < ActiveRecord::Migration[7.2]
  def change
    add_column :tournament_participants, :dropped, :boolean, default: false
  end
end
