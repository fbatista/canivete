# frozen_string_literal: true

class AddSizeToPods < ActiveRecord::Migration[7.0]
  def change
    add_column :pods, :size, :integer, default: 4
  end
end
