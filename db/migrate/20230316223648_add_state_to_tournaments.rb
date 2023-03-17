# frozen_string_literal: true

class AddStateToTournaments < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :state, :integer, null: false, default: 0
  end
end
