# frozen_string_literal: true

require "test_helper"

module Circuits
  class UpdateStandingsJobTest < ActiveJob::TestCase
    setup do
      @circuit = circuits(:standard_circuit)
      @tournament = events(:small_tournament)

      # Set final positions
      @tournament.event_participants.order(:id).each_with_index do |participant, index|
        participant.update!(final_position: index + 1)
      end
    end

    test "enqueues circuit standings update" do
      assert_enqueued_with(job: Circuits::UpdateStandingsJob, args: [@circuit, @tournament]) do
        Circuits::UpdateStandingsJob.perform_later(@circuit, @tournament)
      end
    end

    test "performs circuit standings update immediately" do
      initial_standing_count = @circuit.circuit_standings.count
      assert_equal 0, initial_standing_count

      Circuits::UpdateStandingsJob.perform_now(@circuit, @tournament)

      assert_equal 4, @circuit.circuit_standings.count
      assert_equal 10, @circuit.circuit_standings.sum(:points) # 4+3+2+1
    end
  end
end
