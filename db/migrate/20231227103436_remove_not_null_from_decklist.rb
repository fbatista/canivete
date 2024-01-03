# frozen_string_literal: true

class RemoveNotNullFromDecklist < ActiveRecord::Migration[7.0]
  def change
    change_column_null :tournament_participants, :decklist, true
  end
end
