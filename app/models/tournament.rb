# frozen_string_literal: true

class Tournament < ApplicationRecord
  has_many :rounds, dependent: :destroy
  has_many :tournament_participants, dependent: :destroy

  POD_SIZE = 4
  POINTS_PER_WIN = 5
  POINTS_PER_BYE = 5
  POINTS_PER_LOSS = 0
  POINTS_PER_DRAW = 1

  PLAYERS_ROUNDS_THRESHOLDS = {
    4..4 => { rounds: 1, top: nil },
    5..15 => { rounds: 2, top: 4 },
    16..32 => { rounds: 3, top: 4 },
    33..64 => { rounds: 4, top: 16 },
    65..128 => { rounds: 5, top: 16 },
    129..256 => { rounds: 6, top: 40 },
    257.. => { rounds: 7, top: 40 }
  }.tap do |thresholds|
    thresholds.default_proc = proc do |hash, key|
      range_key = hash.keys.find { |r| r.include?(key) }
      hash.include?(range_key) ? hash[range_key] : nil
    end
  end.freeze

  enum :state, { registration_open: 0, registration_closed: 1, swiss: 2, single_elimination: 3, finished: 4 },
       default: :registration_open

  validates :name, presence: true
  validates :slug, presence: true

  before_validation :populate_slug

  validate :valid_state_transitions, if: -> { state_changed? }

  after_update :perform_state_based_actions, if: -> { state_previously_changed? }

  def populate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]/, '-')
  end

  def valid_state_transitions
    errors.add :state, 'cannot transition backwards' if Tournament.states[state_was] > state_for_database
  end

  def perform_state_based_actions
    case state.to_sym
    when :swiss
      Tournaments::StartRoundJob.perform_now(self)
    when :single_elimination
      Tournaments::TopCutJob.perform_now(self)
    when :finished
      Tournaments::FinishTournamentJob.perform_now(self)
    end
  end
end
