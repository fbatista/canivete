# frozen_string_literal: true

class AddFieldsToTournament < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'postgis'
    change_table :tournaments, bulk: true do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.int4range :participants_range
      t.text :prizes
      t.text :address
      t.text :schedule
      t.text :rules
      t.numeric :price
      t.integer :currency
      t.st_point :location, geographic: true
    end

    add_column :tournament_organizers, :default_currency, :integer, default: 0

    add_index :tournaments, :location, using: :gist
  end
end
