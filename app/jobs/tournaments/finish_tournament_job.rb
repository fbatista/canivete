# frozen_string_literal: true

module Tournaments
  class FinishTournamentJob < ApplicationJob
    def perform(tournament)
      if tournament.circuit.present?
        Circuits::UpdateStandingsJob.perform_now(tournament.circuit, tournament)
      end
    end
  end
end
