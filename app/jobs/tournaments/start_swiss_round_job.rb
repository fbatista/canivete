# frozen_string_literal: true

module Tournaments
  # Service to start the next round
  class StartSwissRoundJob < ApplicationJob
    def perform(tournament)
      tournament.rounds.create(
        type: SwissRound,
        number: tournament.rounds.size + 1
      )
    end
  end
end
