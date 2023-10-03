# frozen_string_literal: true

class Seating < ApplicationRecord
  belongs_to :pod, inverse_of: :seatings
  belongs_to :tournament_participant

  has_one :round, through: :pod

  validates :order, presence: true
end
