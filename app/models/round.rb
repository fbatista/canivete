# frozen_string_literal: true

# Model representing a round in the tournament
class Round < ApplicationRecord
  belongs_to :tournament, counter_cache: true
  has_many :tournament_participants, through: :tournament
  has_many :pods, dependent: :destroy
  has_many :seatings, through: :pods
  has_many(
    :seated_participants,
    through: :seatings, class_name: 'TournamentParticipant',
    source: :tournament_participant
  )

  validates(
    :number,
    {
      presence: true,
      uniqueness: { scope: :tournament_id },
      numericality: true,
      inclusion: { in: 1.. }
    }
  )

  after_create :create_pods

  def create_pods
    Tournaments::CreatePodsJob.perform_now(self)
  end
end
