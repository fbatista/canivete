# frozen_string_literal: true

class AddStartedAtToRounds < ActiveRecord::Migration[7.0]
  def change
    add_column :rounds, :started_at, :datetime
  end
end
