# frozen_string_literal: true

module Tournaments
  class PlayerSorter
    def initialize(round)
      @round = round
    end

    def sorted_players
      players_by_rank = @round.tournament_participants.shuffle
      players_by_rank.sort_by.with_index { |p, i| [-p.rank_score, i] }
    end
  end
end
