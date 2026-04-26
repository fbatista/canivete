# frozen_string_literal: true

# Model representing a round in the tournament
class Round < ApplicationRecord
  belongs_to :event, counter_cache: true
  has_many :event_participants, -> { playing.not_eliminated }, through: :event
  has_many :pods, dependent: :destroy
  has_many :seatings, through: :pods
  has_many :results, dependent: :destroy

  scope :published, -> { where(published: true) }
  scope :finished, -> { where.not(finished_at: nil) }
  scope :play_rounds, -> { where(is_play_round: true) }
  scope :finals_rounds, -> { where(is_finals_round: true) }

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

  def advance_tournament!
    # No-op default. Override in subclasses (SwissRound, SingleEliminationRound).
  end

  def byes
    results
      .where(type: "Advance")
      .where.not(event_participant_id: seatings.select(:event_participant_id))
  end

  private

  def round_finished
    return unless finished_at.present? && finished_at_previously_changed?

    advance_tournament!
  end
end
