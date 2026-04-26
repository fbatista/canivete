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
end
