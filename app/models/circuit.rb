# frozen_string_literal: true

class Circuit < ApplicationRecord
  has_many :tournaments, dependent: :nullify
  has_many :circuit_standings, dependent: :destroy
  belongs_to :event_organizer

  def standings
    circuit_standings.ranked
  end

  def update_standings!
    circuit_standings.update_all(points: 0, events_count: 0)
    circuit_standings.destroy_all
  end
end
