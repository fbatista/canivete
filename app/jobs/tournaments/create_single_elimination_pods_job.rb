# frozen_string_literal: true

module Tournaments
  # Job to create pods for a round
  class CreateSingleEliminationPodsJob < ApplicationJob
    def perform(round)
      @round = round
      @players_to_advance, @players_by_rank, @players_to_eliminate = initialize_players

      generate_pods!

      Tournaments::Strategies::SpreadMatcher.new(@round, @players_by_rank).match_players!

      @round.transaction do
        advance_players!
        eliminate_players!
        @round.pods.each(&:sit_participants!)
      end
    end

    private

    def initialize_players
      sorted_players = Tournaments::PlayerSorter.new(@round).sorted_players
      players_continuing = sorted_players[0...players_making_the_cut]
      players_to_eliminate = sorted_players[players_making_the_cut..]
      players_being_paired = players_continuing.last(players_playing)
      players_to_advance = players_continuing - players_being_paired

      [players_to_advance, players_being_paired, players_to_eliminate]
    end

    def eliminate_players!
      @players_to_eliminate&.each do |player|
        Eliminated.create(round: @round, tournament_participant: player)
      end
    end

    def advance_players!
      @players_to_advance&.each do |player|
        Advance.create(round: @round, tournament_participant: player)
      end
    end

    def generate_pods!
      number_of_pods.times do |i|
        @round.pods.build(number: i + 1, size: @round.tournament.class::PREFERRED_POD_SIZE)
      end
    end

    def players_making_the_cut
      @round.tournament.rounds_info[:top][:players]
    end

    def players_playing
      number_of_pods * @round.tournament.class::PREFERRED_POD_SIZE
    end

    def number_of_pods
      @round.tournament.rounds_info[:top][:pods][@round.number - @round.tournament.number_of_swiss_rounds - 1]
    end
  end
end
