# frozen_string_literal: true

class CreateCircuits < ActiveRecord::Migration[8.0]
  def change
    create_table :circuits, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.references :event_organizer, null: false, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
