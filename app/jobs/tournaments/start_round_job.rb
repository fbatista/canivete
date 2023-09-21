# frozen_string_literal: true

module Tournaments
  class StartRoundJob < ApplicationJob
    def perform(tournament)
      rounds_info = Tournament::PLAYERS_ROUNDS_THRESHOLDS[tournament.tournament_participants.size]
      return unless tournament.rounds.size < rounds_info[:rounds]

      round = tournament.rounds.build(number: tournament.rounds.size + 1)
      round.save
    end
  end
end
