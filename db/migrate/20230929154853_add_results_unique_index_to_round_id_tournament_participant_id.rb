# frozen_string_literal: true

class AddResultsUniqueIndexToRoundIdTournamentParticipantId < ActiveRecord::Migration[7.0]
  def change
    add_index(:results, %i[event_participant_id round_id], unique: true)
  end
end
