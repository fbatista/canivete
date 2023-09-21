# frozen_string_literal: true

class TournamentParticipant < ApplicationRecord
  belongs_to :tournament, counter_cache: true
  belongs_to :player

  has_many :results
  has_many :opponents, through: :results

  has_many :seatings

  validates :decklist, presence: true
  delegate :name, to: :player

  def number_of_draws
    results.count { |result| result.is_a?(Draw) }
  end

  def number_of_wins
    results.count { |result| result.is_a?(Win) }
  end

  def number_of_byes
    results.count { |result| result.is_a?(Bye) }
  end

  def match_points
    @match_points ||= number_of_draws * Tournament::POINTS_PER_DRAW +
                      number_of_wins * Tournament::POINTS_PER_WIN +
                      number_of_byes * Tournament::POINTS_PER_BYE
  end

  def match_win_percentage
    return 0.0 if (results.size - number_of_byes).zero?

    @match_win_percentage ||= (
        match_points - (number_of_byes * Tournament::POINTS_PER_BYE)
      ) / (
        (results.size - number_of_byes) * Tournament::POINTS_PER_WIN
      ).to_f
  end

  def opponents_average_match_points
    return 0.0 if opponents.empty?

    @opponents_average_match_points ||= opponents.inject(0.0) { |sum, n| n.match_points + sum } / opponents.size.to_f
  end

  def opponents_average_match_win_percentage
    return 0.0 if opponents.empty?

    @opponents_average_match_win_percentage ||= opponents.inject(0.0) do |sum, n|
      [n.match_win_percentage, 1.0 / Trounanment::POINTS_PER_WIN].max + sum
    end / opponents.size.to_f
  end

  def rank_score
    @rank_score ||= match_points * 100_000_000_000_000 +
                    (match_win_percentage * 10_000_000_000_000).to_i +
                    (opponents_average_match_points * 10_000_000).to_i +
                    (opponents_average_match_win_percentage * 10_000).to_i
  end
end
