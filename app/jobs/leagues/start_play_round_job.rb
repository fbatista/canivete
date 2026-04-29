# frozen_string_literal: true

module Leagues
  # Service to start the next play round in a league
  class StartPlayRoundJob < ApplicationJob
    def perform(league)
      league.rounds.create(
        type: SwissRound,
        number: league.rounds.size + 1,
        is_play_round: true
      )
    end
  end
end
