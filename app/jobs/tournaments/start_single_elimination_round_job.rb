# frozen_string_literal: true

module Tournaments
  class StartSingleEliminationRoundJob < ApplicationJob
    def perform(tournament)
      tournament.rounds.create(
        type: SingleEliminationRound,
        number: tournament.rounds.size + 1
      )
    end
  end
end
