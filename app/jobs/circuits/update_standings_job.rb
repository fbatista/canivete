# frozen_string_literal: true

module Circuits
  # Background job to update circuit standings after an event finishes.
  # Calculates points based on each player's final position.
  class UpdateStandingsJob < ApplicationJob
    queue_as :default

    def perform(circuit, event)
      Circuits::CalculatePoints.new(circuit, event).award_points!
    end
  end
end
