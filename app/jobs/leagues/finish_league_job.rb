# frozen_string_literal: true

module Leagues
  # Service to finalize a league (calculate standings, etc.)
  class FinishLeagueJob < ApplicationJob
    def perform(league)
      # Finalize league: compute standings, award prizes, etc.
    end
  end
end
