# frozen_string_literal: true

class Pod < ApplicationRecord
  belongs_to :round
  has_one :tournament, through: :round

  has_many :seatings, -> { order(order: :asc) }, dependent: :destroy, inverse_of: :pod
  has_many :tournament_participants, through: :seatings
  has_many :results, ->(pod) { where(results: { round_id: pod.round_id }) }, through: :tournament_participants

  has_many :players, through: :tournament_participants
  has_many :users, through: :players

  attr_accessor :candidates

  validates(
    :number,
    {
      presence: true,
      uniqueness: { scope: :round_id },
      numericality: true,
      inclusion: { in: 1.. }
    }
  )

  after_initialize -> { @candidates = [] }

  def finished?
    results.size == tournament_participants.size
  end

  def receive_candidate(candidate)
    candidates.push(candidate) if !full? && can_match?(candidate)
  end

  def force_candidate(candidate)
    candidates.push(candidate) unless full?
  end

  def full?
    candidates.size == size
  end

  def can_match?(candidate)
    candidates.none? { |participant| participant.played_against?(candidate) }
  end

  def candidates_average_rank
    candidates.sum(&:rank_score) / candidates.size.to_f
  end

  def swap_suitable_by_rank_for?(candidate)
    full? && candidates_average_rank.between?(
      (candidate.match_win_percentage * 1.0 - tournament.class::PAIR_DOWN_DEVIATION_PERCENT),
      (candidate.match_win_percentage * 1.0 + tournament.class::PAIR_DOWN_DEVIATION_PERCENT)
    )
  end

  def swap_suitable_by_rematch_for?(candidate)
    full? && candidates.count { |participant| participant.played_against?(candidate) } <= 1
  end

  def a_swap_candidate_by_rematch_for(candidate)
    candidates.find { |participant| participant.played_against?(candidate) } || candidates.last
  end

  def best_swap_candidate_by_rank_for(player, _round)
    candidates.min { |a, b| (a.rank_score - player.rank_score).abs <=> (b.rank_score - player.rank_score).abs }
  end

  def swap_candidates!(new_candidate, existing_candidate)
    candidates.delete(existing_candidate)
    candidates.push(new_candidate)
  end

  def sit_participants!
    candidates.shuffle.sort_by.with_index do |participant, i|
      (1..size).to_a.map do |position|
        participant.times_going_at(position)
      end + [-participant.rank_score, i]
    end.each.with_index do |participant, i|
      seatings.build(tournament_participant: participant, order: i + 1)
    end

    candidates = []

    save!
  end
end
