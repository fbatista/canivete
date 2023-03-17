# frozen_string_literal: true

class TournamentParticipant < ApplicationRecord
  belongs_to :tournament
  belongs_to :player

  has_many :results
  has_many :opponents, through: :results

  has_many :seatings

  validates :decklist, presence: true
  delegate :name, to: :player

  def points; end
end
