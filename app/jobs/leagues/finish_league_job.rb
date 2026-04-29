# frozen_string_literal: true

module Leagues
  # Service to finalize a league (calculate standings, etc.)
  class FinishLeagueJob < ApplicationJob
    def perform(league)
      if league.circuit.present?
        Circuits::UpdateStandingsJob.perform_now(league.circuit, league)
      end
    end
  end
end
