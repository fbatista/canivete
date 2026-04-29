# frozen_string_literal: true

module Circuits
  # Awards circuit points to players based on their final position in an event.
  # Points formula: (total_participants - final_position + 1) per position.
  # Players who finish with no position (nil) get no points.
  class CalculatePoints
    def initialize(circuit, event)
      @circuit = circuit
      @event = event
    end

    def award_points!
      participants = @event.event_participants
        .where.not(final_position: nil)
        .order(final_position: :asc)

      total = participants.size
      participants.each do |participant|
        standing = @circuit.circuit_standings.find_or_initialize_by(player: participant.player)
        position_points = (total - participant.final_position + 1).to_f
        standing.points += position_points
        standing.events_count += 1
        standing.save!
      end
    end

    private

    attr_reader :circuit, :event
  end
end
