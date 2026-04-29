# frozen_string_literal: true

class CircuitStanding < ApplicationRecord
  belongs_to :circuit
  belongs_to :player

  scope :ranked, -> { order(points: :desc) }
  scope :for_circuit, ->(circuit) { where(circuit: circuit) }

  validates :circuit_id, uniqueness: { scope: :player_id }
end
