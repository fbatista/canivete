# frozen_string_literal: true

require "test_helper"

class CircuitTest < ActiveSupport::TestCase
  test "circuit has correct associations" do
    circuit = circuits(:standard_circuit)
    assert_respond_to circuit, :tournaments
    assert_respond_to circuit, :event_organizer
  end

  test "circuit belongs to event_organizer" do
    circuit = circuits(:standard_circuit)
    assert_not_nil circuit.event_organizer
    assert_instance_of EventOrganizer, circuit.event_organizer
  end

  test "circuit has many tournaments" do
    circuit = circuits(:standard_circuit)
    assert_respond_to circuit, :tournaments
  end

  test "circuit has many circuit_standings" do
    circuit = circuits(:standard_circuit)
    assert_respond_to circuit, :circuit_standings
  end

  test "circuit responds to standings method" do
    circuit = circuits(:standard_circuit)
    assert_respond_to circuit, :standings
  end

  test "standings returns ranked standings" do
    circuit = circuits(:standard_circuit)
    p1 = users(:player_one).player
    p2 = users(:player_two).player
    standing1 = circuit.circuit_standings.create!(player: p1, points: 10)
    standing2 = circuit.circuit_standings.create!(player: p2, points: 20)

    # Re-query to ensure fresh data
    circuit.reload
    ranked = circuit.standings.to_a

    assert_equal 2, ranked.size
    assert_equal standing2.player_id, ranked.first.player_id
    assert_equal standing1.player_id, ranked.last.player_id
  end

  test "update_standings! clears all standings" do
    circuit = circuits(:standard_circuit)
    p1 = users(:player_one).player
    p2 = users(:player_two).player
    circuit.circuit_standings.create!(player: p1, points: 10, events_count: 2)
    circuit.circuit_standings.create!(player: p2, points: 5, events_count: 1)

    assert_equal 2, circuit.circuit_standings.count

    circuit.update_standings!

    assert_equal 0, circuit.circuit_standings.count
  end

  test "circuit scope for_organizer filters by organizer" do
    organizer = event_organizers(:standard_organizer)
    circuits = Circuit.for_organizer(organizer)
    assert_includes circuits, circuits(:standard_circuit)
  end
end
