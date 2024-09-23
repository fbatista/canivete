# frozen_string_literal: true

class Tournament < ApplicationRecord # rubocop:disable Metrics/ClassLength
  belongs_to :tournament_organizer
  has_many :rounds, dependent: :destroy
  has_many :tournament_participants, dependent: :destroy

  scope :for_organizer, ->(organizer) { where(tournament_organizer: organizer) }

  PREFERRED_POD_SIZE = 4
  SMALLER_POD_SIZE = 3
  LARGER_POD_SIZE = 5
  POINTS_PER_WIN = 7
  POINTS_PER_LOSS = 0
  POINTS_PER_DRAW = 1
  PAIR_DOWN_DEVIATION_PERCENT = 0.1

  PLAYERS_ROUNDS_THRESHOLDS = {
    4..5 => {
      rounds: [{ swiss_round: :standard }],
      top: nil
    },
    6..16 => {
      rounds: [{ swiss_round: :standard }, { swiss_round: :standard }],
      top: { players: 4, pods: [1] }
    },
    17..24 => {
      rounds: [{ swiss_round: :standard }, { swiss_round: :spread }, { swiss_round: :standard }],
      top: { players: 7, pods: [1, 1] }
    },
    25..32 => {
      rounds: [{ swiss_round: :standard }, { swiss_round: :spread }, { swiss_round: :standard },
               { swiss_round: :forced }],
      top: { players: 10, pods: [2, 1] }
    },
    33..40 => {
      rounds: [{ swiss_round: :standard },
               { swiss_round: :spread }] + ([{ swiss_round: :standard }] * 2) + [{ swiss_round: :forced }],
      top: { players: 13, pods: [2, 1] }
    },
    41..64 => {
      rounds: [{ swiss_round: :standard },
               { swiss_round: :spread }] + ([{ swiss_round: :standard }] * 2) + [{ swiss_round: :forced }],
      top: { players: 16, pods: [4, 1] }
    },
    65..128 => {
      rounds: [{ swiss_round: :standard },
               { swiss_round: :spread }] + ([{ swiss_round: :standard }] * 3) + [{ swiss_round: :forced }],
      top: { players: 16, pods: [4, 1] }
    },
    129..256 => {
      rounds: [{ swiss_round: :standard },
               { swiss_round: :spread }] + ([{ swiss_round: :standard }] * 4) + [{ swiss_round: :forced }],
      top: { players: 40, pods: [8, 4, 1] }
    },
    257..512 => {
      rounds: [{ swiss_round: :standard },
               { swiss_round: :spread }] + ([{ swiss_round: :standard }] * 5) + [{ swiss_round: :forced }],
      top: { players: 40, pods: [8, 4, 1] }
    },
    513.. => {
      rounds: [{ swiss_round: :standard },
               { swiss_round: :spread }] + ([{ swiss_round: :standard }] * 6) + [{ swiss_round: :forced }],
      top: { players: 64, pods: [16, 4, 1] }
    }
  }.tap do |thresholds|
    thresholds.default_proc = proc do |hash, key|
      return nil unless key.is_a?(Integer)

      range_key = hash.keys.find { |r| r.include?(key) }

      hash[range_key]
    end
  end.freeze

  enum :state, {
    registration_open: 0,
    registration_closed: 1,
    swiss: 2,
    single_elimination: 3,
    finished: 4,
    canceled: 5
  }, default: :registration_open

  TRANSITIONS = {
    registration_open: %i[registration_closed canceled],
    registration_closed: %i[swiss canceled],
    swiss: %i[single_elimination finished canceled]
  }.with_indifferent_access.freeze

  has_one_attached :cover

  validates :state, presence: true
  validates :name, presence: true
  validates :slug, presence: true

  before_validation :populate_slug

  validate :valid_state_transitions, if: -> { state_changed? }

  after_update :perform_state_based_actions, if: -> { state_previously_changed? }

  def latitude=(latitude)
    self.location = RGeo::Geographic
      .spherical_factory(srid: 4326)
      .point(longitude, latitude)
  end

  def longitude=(longitude)
    self.location = RGeo::Geographic
      .spherical_factory(srid: 4326)
      .point(longitude, latitude)
  end

  def latitude
    location&.y || 0
  end

  def longitude
    location&.x || 0
  end

  def minimum_participants=(num_players)
    self.participants_range = (num_players || 0)..maximum_participants
  end

  def maximum_participants=(num_players)
    self.participants_range = minimum_participants..num_players
  end

  def minimum_participants
    participants_range&.first || 0
  end

  def maximum_participants
    participants_range&.last.nil? ? Float::INFINITY : participants_range&.last
  end

  def available_states
    return Tournament.states.slice(:registration_open) if new_record?

    Tournament.states.slice(*TRANSITIONS[state])
  end

  def rounds_info
    PLAYERS_ROUNDS_THRESHOLDS[tournament_participants.size]
  end

  def number_of_swiss_rounds
    rounds_info[:rounds].size
  end

  def number_of_single_elimination_rounds
    rounds_info.dig(:top, :pods)&.size
  end

  def live?
    state_for_database > Tournament.states[:registration_closed]
  end

  def populate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]/, '-')
  end

  def valid_state_transitions
    unless state_was.present? && Tournament.states.key?(state_was) && Tournament.states[state_was] > state_for_database
      return
    end

    errors.add :state, 'cannot transition backwards'
  end

  def perform_state_based_actions
    case state.to_sym
    when :swiss
      Tournaments::StartSwissRoundJob.perform_now(self)
    when :single_elimination
      Tournaments::StartSingleEliminationRoundJob.perform_now(self)
    when :finished
      Tournaments::FinishTournamentJob.perform_now(self)
    end
  end
end
