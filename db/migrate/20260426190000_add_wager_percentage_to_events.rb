# frozen_string_literal: true

class AddWagerPercentageToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :wager_percentage, :decimal, precision: 5, scale: 2
  end
end
