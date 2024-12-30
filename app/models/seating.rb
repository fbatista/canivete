# frozen_string_literal: true

class Seating < ApplicationRecord
  belongs_to :pod, inverse_of: :seatings
  belongs_to :tournament_participant

  has_one :round, through: :pod

  scope :publishable, -> { joins(:round).where.not(rounds: { finished_at: nil }) }

  validates :order, presence: true
end
