# frozen_string_literal: true

class AddFinishedAtToRounds < ActiveRecord::Migration[7.2]
  def change
    add_column :rounds, :finished_at, :datetime
  end
end
