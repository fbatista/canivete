# frozen_string_literal: true

module Tournaments
  module Strategies
    class SwissMatcher
      def initialize(round, sorted_players, forced: false)
        @round = round
        @sorted_players = sorted_players
        @forced = forced
        @player_pods = {}
      end

      def match_players!
        initial_match!
        handle_unmatched_players!
      end

      private

      def initial_match!
        @round.pods.each do |pod|
          @sorted_players.each do |player|
            next if @player_pods[player].present?

            match!(player:, pod:, forced: @forced)

            break if pod.full?
          end
        end
      end

      def handle_unmatched_players!
        unmatched_players.each do |player|
          next if attempt_swaping!(player:) == :success

          match!(player:, pod: @round.pods.reject(&:full?).last)
        end
      end

      def attempt_swaping!(player:)
        @round.pods.select(&:full?).sort { |a, b| sort_pod_by_rank_diff(a, b, player:) }.each do |pod|
          next unless pod.swap_suitable_by_rank_for?(player)

          candidate_player = find_swap_candidate(pod:, player:)
          candidate_pod = incomplete_pods.find { |incomplete_pod| incomplete_pod.can_match?(candidate_player) }
          next unless candidate_pod

          swap!(unmatched_player: player, matched_player: candidate_player, pod:, candidate_pod:)
          break(:success)
        end
        :failure
      end

      def sort_pod_by_rank_diff(pod_a, pod_b, player:)
        (pod_a.candidates_average_rank - player.rank_score).abs <=>
          (pod_b.candidates_average_rank - player.rank_score).abs
      end

      def incomplete_pods
        @round.pods.reject(&:full?).reverse
      end

      def find_swap_candidate(pod:, player:)
        if pod.swap_suitable_by_rematch_for?(player)
          pod.a_swap_candidate_by_rematch_for(player)
        else
          pod.best_swap_candidate_by_rank_for(player)
        end
      end

      def match!(player:, pod:, forced: false)
        success = forced ? pod&.receive_candidate(player) : pod&.force_candidate(player)
        @player_pods[player] = pod if success
      end

      def swap!(unmatched_player:, matched_player:, pod:, candidate_pod:)
        pod.swap!(unmatched_player, matched_player)
        @player_pods[unmatched_player] = pod
        @player_pods.delete(matched_player)
        match!(player: matched_player, pod: candidate_pod)
      end

      def unmatched_players
        @sorted_players.reject { |player| @player_pods[player].present? }
      end
    end
  end
end
