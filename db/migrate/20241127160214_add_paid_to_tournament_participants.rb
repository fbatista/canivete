# frozen_string_literal: true

class AddPaidToTournamentParticipants < ActiveRecord::Migration[7.2]
  def change
    change_table :tournament_participants, bulk: true do |t|
      t.boolean :paid, default: false, null: false
      t.boolean :checked_in, default: false, null: false
      t.integer :fixed_pod
    end

    add_column :rounds, :published, :boolean, default: false, null: false

    create_table :rooms, id: :uuid do |t|
      t.belongs_to :tournament, foreign_key: true, type: :uuid, index: true
      t.text :name
      t.int4range :pod_range
      t.integer :pods_per_row
      t.timestamps
    end
  end
end
