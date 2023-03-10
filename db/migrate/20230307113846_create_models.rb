class CreateModels < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pgcrypto'
    create_table :users, id: :uuid do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :name, null: false
      t.timestamps
    end

    create_table :players, id: :uuid do |t|
      t.belongs_to :user, foreign_key: true, type: :uuid, index: true
      t.string :key, null: false, index: true
      t.timestamps
    end

    create_table :tournaments, id: :uuid do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    create_table :rounds, id: :uuid do |t|
      t.belongs_to :tournament, foreign_key: true, type: :uuid, index: true
      t.integer :number, null: false
      t.timestamps
    end

    create_table :pods, id: :uuid do |t|
      t.belongs_to :round, foreign_key: true, type: :uuid, index: true
      t.integer :number, null: false
      t.timestamps
    end

    create_table :tournament_participants, id: :uuid do |t|
      t.belongs_to :tournament, foreign_key: true, type: :uuid, index: true
      t.belongs_to :player, foreign_key: true, type: :uuid, index: true
      t.string :decklist, null: false
      t.timestamps
    end

    create_table :results, id: :uuid do |t|
      t.belongs_to :round, foreign_key: true, type: :uuid, index: true
      t.belongs_to :tournament_participant, foreign_key: true, type: :uuid, index: true
      t.string :type, null: false
      t.timestamps
    end

    create_table :seatings, id: :uuid do |t|
      t.belongs_to :pod, foreign_key: true, type: :uuid, index: true
      t.belongs_to :tournament_participant, foreign_key: true, type: :uuid, index: true
      t.integer :order, null: false, default: 1
      t.timestamps
    end
  end
end
