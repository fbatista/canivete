# frozen_string_literal: true

class CreateTo < ActiveRecord::Migration[7.0]
  def change
    create_table :tournament_organizers, id: :uuid do |t|
      t.belongs_to :user, foreign_key: true, type: :uuid, index: true
      t.timestamps
    end
  end
end
