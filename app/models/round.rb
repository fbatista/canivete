# frozen_string_literal: true

# Model representing a round in the tournament
class Round < ApplicationRecord
  belongs_to :tournament, counter_cache: true
  has_many :tournament_participants, -> { playing.not_eliminated }, through: :tournament
  has_many :pods, dependent: :destroy
  has_many :seatings, through: :pods
  has_many :results, dependent: :destroy

  after_create :create_pods
  after_update :round_finished

  def finished?
    pods.all?(&:finished?)
  end

  def started?
    started_at.present?
  end

  def past?
    finished_at.present?
  end

  def byes
    results
      .where(type: 'Advance')
      .where.not(tournament_participant_id: seatings.select(:tournament_participant_id))
  end

  private

  def round_finished
    return unless finished_at_previously_changed?

    advance_tournament!
  end
end
