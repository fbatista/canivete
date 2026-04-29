# frozen_string_literal: true

class AddFinalPositionToEventParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :event_participants, :final_position, :integer
  end
end
