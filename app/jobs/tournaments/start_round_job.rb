# frozen_string_literal: true

module Tournaments
  # Service to start the next round
  class StartRoundJob < ApplicationJob
    def perform(tournament)
      return unless tournament.rounds.size < tournament.rounds_info[:rounds].size

      tournament.rounds.create(
        type: load_round_type(tournament),
        number: tournament.rounds.size + 1
      )
    end

    def load_round_type(tournament)
      tournament.rounds_info[:rounds][tournament.rounds.size].keys.first.to_s.classify
    end
  end
end
