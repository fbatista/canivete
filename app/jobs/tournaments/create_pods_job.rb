# frozen_string_literal: true

module Tournaments
  # Job to create pods for a round
  # rubocop:disable Metrics/ClassLength
  class CreatePodsJob < ApplicationJob
    def perform(round) # rubocop:disable Metrics/MethodLength
      @round = round
      calculate_number_of_pods!
      build_pods!
      @players_by_rank = @round.tournament_participants.shuffle
      @players_by_rank = @players_by_rank.sort_by.with_index { |p, i| [-p.rank_score, i] }
      @player_pods = {}

      pair_using_strategy

      @round.transaction do
        award_byes!
        @round.pods.each(&:sit_participants!)
      end
    end

    private

    def build_pods! # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      i = 1
      @large.times do |n|
        @round.pods.build(number: i + n, size: @round.tournament.class::LARGER_POD_SIZE)
        i += 1
      end
      @preferred.times do |n|
        @round.pods.build(number: i + n, size: @round.tournament.class::PREFERRED_POD_SIZE)
        i += 1
      end
      @small.times do |n|
        @round.pods.build(number: i + n, size: @round.tournament.class::SMALLER_POD_SIZE)
        i += 1
      end
    end

    def pair_using_strategy
      case load_strategy
      when :spread
        spread_match!
      when :bubble
        initial_match! { |player, pod| force!(player:, pod:) }
      when :standard
        initial_match! { |player, pod| match!(player:, pod:) }
      end
      handle_unmatched_players!
    end

    def load_strategy
      @round.tournament.rounds_info[:rounds][@round.number - 1].values.first
    end

    def calculate_number_of_pods! # rubocop:disable Metrics/AbcSize
      @large = 1, @preferred = @small = 0
      return if @players_by_rank.size == @round.tournament.class::LARGER_POD_SIZE

      @preferred = n / @round.tournament.class::PREFERRED_POD_SIZE
      remaining_items = n % @round.tournament.class::PREFERRED_POD_SIZE

      if remaining_items.positive?
        @preferred -= @round.tournament.class::SMALLER_POD_SIZE - remaining_items
        remaining_items += (@round.tournament.class::SMALLER_POD_SIZE - remaining_items) *
                           @round.tournament.class::PREFERRED_POD_SIZE
      end

      @large = 0, @small = remaining_items / @round.tournament.class::SMALLER_POD_SIZE
    end

    def spread_match!
      @players_by_rank.each.with_index do |player, i|
        force!(player:, pod: serpent_pod(@round.pods, i))
      end
    end

    def serpent_pod(pods, index)
      i = (index / pods.size).even? ? (index % pods.size) : -1 * ((index + 1) % pods.size)
      if pods[i].full?
        serpent_pod(pods, index + 1)
      else
        pods[i]
      end
    end

    def initial_match!(round)
      number_of_pods = number_of_complete_pods
      number_of_pods.times do |i|
        pod = round.pods.build(number: i + 1)
        @players_by_rank.each do |player|
          next if @player_pods[player].present?

          yield(player, pod)

          break if pod.full?
        end
      end
    end

    def handle_unmatched_players!(round)
      unmatched_players.each do |player|
        next if attempt_swaping!(player:, round:) == :success

        match!(player:, pod: round.pods.reject(&:full?).last)
      end
    end

    def attempt_swaping!(player:, round:)
      round.pods.select(&:full?).sort { |a, b| sort_pod_by_rank_diff(a, b, player:) }.each do |pod|
        next unless pod.swap_suitable_by_rank_for?(player)

        candidate_player = find_swap_candidate(pod:, player:)
        candidate_pod = incomplete_pods(round).find { |incomplete_pod| incomplete_pod.can_match?(candidate_player) }
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

    def incomplete_pods(round)
      round.pods.reject(&:full?).reverse
    end

    def find_swap_candidate(pod:, player:)
      if pod.swap_suitable_by_rematch_for?(player)
        pod.a_swap_candidate_by_rematch_for(player)
      else
        pod.best_swap_candidate_by_rank_for(player)
      end
    end

    def force_rematch!(round:)
      number_of_players_to_rematch = unmatched_players.size - number_of_byes(round)
      return unless number_of_players_to_rematch.positive?

      round.pods.reject(&:full?).each do |pod|
        unmatched_players.first(number_of_players_to_rematch).each do |player|
          next if @player_pods[player].present?

          force!(player:, pod:)

          break if pod.full?
        end
      end
    end

    def match!(player:, pod:)
      @player_pods[player] = pod if pod&.receive_candidate(player)
    end

    def force!(player:, pod:)
      @player_pods[player] = pod if pod&.force_candidate(player)
    end

    def swap!(unmatched_player:, matched_player:, pod:, candidate_pod:)
      pod.swap!(unmatched_player, matched_player)
      @player_pods[unmatched_player] = pod
      @player_pods.delete(matched_player)
      match!(player: matched_player, pod: candidate_pod)
    end

    def unmatched_players
      @players_by_rank.reject { |player| @player_pods[player].present? }
    end
  end
  # rubocop:enable Metrics/ClassLength
end
