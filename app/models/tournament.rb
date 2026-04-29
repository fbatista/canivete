# frozen_string_literal: true

class Tournament < Event # rubocop:disable Metrics/ClassLength
  paginates_per 20

  scope :ongoing, -> { where(state: %i[swiss single_elimination]) }

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
    thresholds.default_proc =
      proc do |hash, key|
        next nil unless key.is_a?(Integer)

        range_key = hash.keys.find { |r| r.include?(key) }

        hash[range_key]
      end
  end.freeze

  enum :state, {
    draft: 0,
    registration_open: 1,
    registration_closed: 2,
    swiss: 3,
    single_elimination: 4,
    finished: 5,
    canceled: 6
  }, default: :registration_open

  TRANSITIONS = {
    draft: %i[draft registration_open registration_closed],
    registration_open: %i[registration_open registration_closed canceled],
    registration_closed: %i[registration_closed swiss canceled],
    swiss: %i[single_elimination finished canceled],
    single_elimination: %i[finished canceled],
    finished: [:finished],
    canceled: [:canceled]
  }.with_indifferent_access.freeze

  def rounds_info
    PLAYERS_ROUNDS_THRESHOLDS[event_participants.size]
  end

  def progress_percent
    (rounds.finished.count.to_f / (number_of_swiss_rounds + number_of_single_elimination_rounds)) * 100
  end

  def number_of_swiss_rounds
    rounds_info[:rounds].size
  end

  def number_of_single_elimination_rounds
    rounds_info.dig(:top, :pods)&.size || 0
  end

  def single_elimination_round_name(round_number)
    %w[Finals Semi-Finals Quarter-Finals][number_of_swiss_rounds + number_of_single_elimination_rounds - round_number]
  end

  def ongoing?
    %w[swiss single_elimination].include?(state)
  end

  def perform_state_based_actions
    return unless TRANSITIONS[state_previously_was.to_sym].include?(state.to_sym)

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
