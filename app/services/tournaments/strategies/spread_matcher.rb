# frozen_string_literal: true

module Tournaments
  module Strategies
    class SpreadMatcher
      def initialize(round, sorted_players)
        @round = round
        @sorted_players = sorted_players
      end

      def match_players!
        @sorted_players.each.with_index do |player, i|
          serpent_pod(@round.pods, i).force_candidate(player)
        end
      end

      private

      def serpent_pod(pods, index)
        i = (index / pods.size).even? ? (index % pods.size) : -1 * ((index + 1) % pods.size)
        if pods[i].full?
          serpent_pod(pods, index + 1)
        else
          pods[i]
        end
      end
    end
  end
end
