# frozen_string_literal: true

module Tournaments
  # Job to create pods for a round
  class CreatePodsJob < ApplicationJob
    def perform(round)
      @players_by_rank = round.tournament_participants.shuffle
      @players_by_rank = @players_by_rank.sort_by.with_index { |p, i| [-p.rank_score, i] } if round.number == 1
      @player_pods = {}

      simple_match!(round)

      handle_unmatched_players!(round)

      round.transaction do
        award_byes!(unmatched_players:, round:)
        round.pods.each(&:sit_participants!)
      end
    end

    private

    def simple_match!(round)
      number_of_pods = @players_by_rank.size / round.tournament.class::POD_SIZE
      number_of_pods.times do |i|
        pod = round.pods.build(number: i + 1)
        @players_by_rank.each do |player|
          next if @player_pods[player].present?

          match!(player:, pod:)

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

    def award_byes!(unmatched_players:, round:)
      unmatched_players.each do |unmatched_player|
        round.results.create!(type: Bye.class.name, tournament_participant: unmatched_player)
      end
    end

    def match!(player:, pod:)
      @player_pods[player] = pod if pod&.receive_candidate(player)
    end

    def swap!(unmatched_player:, matched_player:, pod:, candidate_pod:)
      pod.swap!(unmatched_player, matched_player)
      @player_pods[unmatched_player] = pod
      @plauer_pods.delete(matched_player)
      match!(player: matched_player, pod: candidate_pod)
    end

    def unmatched_players
      @players_by_rank.reject { |player| @player_pods[player].present? }
    end
  end
end
