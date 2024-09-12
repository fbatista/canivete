# frozen_string_literal: true

# The tournament representation of a player
class TournamentParticipant < ApplicationRecord
  belongs_to :tournament, counter_cache: true
  belongs_to :player

  has_many :results, -> { publishable }, dependent: :destroy, inverse_of: :tournament_participant

  has_many :seatings, dependent: :destroy
  has_many :pods, -> { publishable }, through: :seatings
  has_many(
    :opponents,
    lambda { |tournament_participant|
      where.not(tournament_participants: { id: tournament_participant.id })
      .where(
        <<~SQL
          pods.id not in (
            select pods.id
            from pods
            inner join rounds on pods.round_id = rounds.id
            where rounds.type = 'SingleEliminationRound'
          )
        SQL
      )
    }, class_name: 'TournamentParticipant', through: :pods, source: :tournament_participants
  )

  scope :playing, -> { where(dropped: false) }
  scope :not_eliminated, lambda {
    where(
      <<~SQL
        not exists (
          select 1
          from results
          where results.tournament_participant_id = tournament_participants.id
            and results.type = 'Eliminated'
        )
      SQL
    )
  }

  validates :decklist, presence: true, unless: proc { |tp| tp.tournament.registration_open? }
  delegate :name, to: :player

  SINGLE_ELIM_COEFF = 100_000_000_000_000_000
  MP_COEFF = 100_000_000_000_000
  MW_COEFF = 10_000_000_000_000
  OAMW_COEFF = 10_000_000
  OAMP_COEFF = 10_000

  def initialize(attributes = nil)
    @match_points = nil
    @match_win_percentage = nil
    @opponents_average_match_points = nil
    @opponents_average_match_win_percentage = nil
    @rank_score = nil
    super
  end

  def playing?
    !dropped
  end

  def played_in_smaller_pod?(except_in:)
    pods.where.not(round_id: except_in).any? { |pod| pod.size == tournament.class::SMALLER_POD_SIZE }
  end

  def times_going_at(position)
    seatings.count { |seat| seat.order == position }
  end

  def played_against?(another)
    opponents.include?(another)
  end

  def corrected_opponents
    opponents.to_a + Array.new(number_of_ghost_opponents) { Ghost.new }
  end

  def number_of_ghost_opponents
    pods.count { |pod|
      pod.size == tournament.class::SMALLER_POD_SIZE
    } * (tournament.class::PREFERRED_POD_SIZE - tournament.class::SMALLER_POD_SIZE)
  end

  def number_of_advancements
    results.count { |result| result.is_a?(Advance) }
  end

  def number_of_draws
    results.count { |result| result.is_a?(Draw) }
  end

  def number_of_wins
    results.count { |result| result.is_a?(Win) }
  end

  def number_of_losses
    results.count { |result| result.is_a?(Loss) || result.is_a?(Penalty) }
  end

  def match_points
    @match_points ||= number_of_draws * Tournament::POINTS_PER_DRAW +
                      number_of_wins * Tournament::POINTS_PER_WIN
  end

  def match_win_percentage
    return 0.0 if results.empty?

    @match_win_percentage ||= match_points / (results.size * Tournament::POINTS_PER_WIN).to_f
  end

  def opponents_average_match_points
    return 0.0 if corrected_opponents.empty?

    @opponents_average_match_points ||= (
      corrected_opponents.inject(0.0) { |sum, n| n.match_points + sum } / corrected_opponents.size.to_f
    ).round(2)
  end

  def opponents_average_match_win_percentage
    return 0.0 if corrected_opponents.empty?

    @opponents_average_match_win_percentage ||=
      corrected_opponents.inject(0.0) do |sum, n|
        [n.match_win_percentage, 1.0 / Tournament::POINTS_PER_WIN].max + sum
      end / corrected_opponents.size.to_f
  end

  def rank_score # rubocop:disable Metrics/AbcSize
    @rank_score ||= number_of_advancements * SINGLE_ELIM_COEFF +
                    match_points * MP_COEFF +
                    (match_win_percentage.round(4) * MW_COEFF).to_i +
                    (opponents_average_match_points * OAMP_COEFF).to_i +
                    (opponents_average_match_win_percentage.round(4) * OAMW_COEFF).to_i
  end
end
