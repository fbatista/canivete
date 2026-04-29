# frozen_string_literal: true

class AddCircuitIdToEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :events, :circuit, type: :uuid, foreign_key: true, null: true
  end
end
