# frozen_string_literal: true

module Leagues
  # Service to start the finals round in a league
  class StartFinalsRoundJob < ApplicationJob
    def perform(league)
      league.rounds.create(
        type: SingleEliminationRound,
        number: league.rounds.size + 1,
        is_finals_round: true
      )
    end
  end
end
