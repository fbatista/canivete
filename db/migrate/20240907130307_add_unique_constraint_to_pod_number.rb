# frozen_string_literal: true

class AddUniqueConstraintToPodNumber < ActiveRecord::Migration[7.0]
  def change
    add_index(:pods, %i[number round_id], unique: true)
  end
end
