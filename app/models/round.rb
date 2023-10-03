# frozen_string_literal: true

# Model representing a round in the tournament
class Round < ApplicationRecord
  belongs_to :tournament, counter_cache: true
  has_many :tournament_participants, through: :tournament
  has_many :pods, dependent: :destroy
  has_many :seatings, through: :pods
  has_many :results, dependent: :destroy

  after_create :create_pods

  def finished?
    pods.all?(&:finished?)
  end

  def started?
    started_at.present?
  end
end
