# frozen_string_literal: true

class AddPlayModeToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :play_mode, :integer, default: 0, null: false
  end
end
