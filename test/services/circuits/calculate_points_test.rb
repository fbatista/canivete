# frozen_string_literal: true

require "test_helper"

module Circuits
  class CalculatePointsTest < ActiveSupport::TestCase
    setup do
      @circuit = circuits(:standard_circuit)
      @tournament = events(:small_tournament)

      # Set final positions for the 4 participants
      @tournament.event_participants.order(:id).each_with_index do |participant, index|
        participant.update!(final_position: index + 1)
      end
    end

    test "awards points based on final position" do
      participants = @tournament.event_participants
        .where.not(final_position: nil)
        .order(:final_position)

      total = participants.size

      Circuits::CalculatePoints.new(@circuit, @tournament).award_points!

      participants.each do |participant|
        standing = @circuit.circuit_standings.find_by(player: participant.player)
        expected_points = total - participant.final_position + 1
        assert_equal expected_points, standing.points
        assert_equal 1, standing.events_count
      end
    end

    test "first place gets the most points" do
      Circuits::CalculatePoints.new(@circuit, @tournament).award_points!

      first_place = @tournament.event_participants.find_by(final_position: 1)
      standing = @circuit.circuit_standings.find_by(player: first_place.player)

      assert_equal 4, standing.points
    end

    test "last place gets one point" do
      Circuits::CalculatePoints.new(@circuit, @tournament).award_points!

      last_place = @tournament.event_participants.find_by(final_position: 4)
      standing = @circuit.circuit_standings.find_by(player: last_place.player)

      assert_equal 1, standing.points
    end

    test "skips participants without final_position" do
      @tournament.event_participants.find_by(id: @tournament.event_participants.first.id)
        .update!(final_position: nil)

      Circuits::CalculatePoints.new(@circuit, @tournament).award_points!

      # Only 3 participants have positions, so 3 standing records
      assert_equal 3, @circuit.circuit_standings.count
      # With total=3: positions 2→2pts, 3→1pt, 4→0pts = 3 total
      assert_equal 3.0, @circuit.circuit_standings.sum(:points)
    end

    test "accumulates points across multiple events" do
      Circuits::CalculatePoints.new(@circuit, @tournament).award_points!

      first_player = @tournament.event_participants.find_by(final_position: 1)
      standing = @circuit.circuit_standings.find_by(player: first_player.player)
      assert_equal 4, standing.points
      assert_equal 1, standing.events_count

      # Simulate a second event by running the same tournament again
      Circuits::CalculatePoints.new(@circuit, @tournament).award_points!

      standing.reload
      assert_equal 8, standing.points
      assert_equal 2, standing.events_count
    end

    test "creates standing record if one does not exist" do
      @circuit.circuit_standings.delete_all

      assert_equal 0, @circuit.circuit_standings.count

      Circuits::CalculatePoints.new(@circuit, @tournament).award_points!

      assert_equal 4, @circuit.circuit_standings.count
    end

    test "uses find_or_initialize_by pattern (no error on duplicate)" do
      first_player = @tournament.event_participants.find_by(final_position: 1)
      @circuit.circuit_standings.find_or_create_by!(player: first_player.player) do |s|
        s.points = 10
        s.events_count = 2
      end

      initial_points = @circuit.circuit_standings.find_by(player: first_player.player).points

      Circuits::CalculatePoints.new(@circuit, @tournament).award_points!

      standing = @circuit.circuit_standings.find_by(player: first_player.player)
      assert_equal initial_points + 4, standing.points
    end
  end
end
