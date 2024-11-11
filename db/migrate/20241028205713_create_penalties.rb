# frozen_string_literal: true

class CreatePenalties < ActiveRecord::Migration[7.2]
  def change
    create_table :infractions, id: :uuid do |t|
      t.belongs_to :player, foreign_key: true, type: :uuid, index: true
      t.belongs_to :tournament, foreign_key: true, type: :uuid, index: true
      t.belongs_to :pod, foreign_key: true, type: :uuid, index: true
      t.integer :kind, default: 200, null: false
      t.integer :category, default: 205, null: false
      t.integer :penalty, default: 0, null: false
      t.text :description
      t.timestamps
    end

    add_column :pods, :extra_time, :integer, default: 0, null: false
  end
end
