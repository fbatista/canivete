# frozen_string_literal: true

require "test_helper"

class Tournaments::GeocodeJobTest < ActiveJob::TestCase
  test "successfully geocodes address and updates tournament location" do
    tournament = tournaments(:small_tournament)
    tournament.update!(address: "Porto, Portugal")

    # Mock the Nominatim API response with exact parameters and headers
    stub_request(:get, "https://nominatim.openstreetmap.org/search")
      .with(
        query: { "limit" => "1", "format" => "jsonv2", "q" => "Porto, Portugal" },
        headers: {
          "User-Agent" => "Canivete webapp backend",
          "Referrer" => "https://canivete.pt",
          "Content-Type" => "application/json; charset=UTF-8"
        }
      )
      .to_return(
        status: 200,
        body: JSON.generate([
          {
            "lat" => "41.1579438",
            "lon" => "-8.6291053",
            "display_name" => "Porto, Portugal"
          }
        ]),
        headers: { "Content-Type" => "application/json" }
      )

    # Perform the job
    Tournaments::GeocodeJob.perform_now(tournament)

    # Verify location was updated
    tournament.reload
    assert_not_nil tournament.location
    assert_in_delta 41.1579438, tournament.latitude, 0.001
    assert_in_delta(-8.6291053, tournament.longitude, 0.001)
  end

  test "handles empty geocoding response gracefully" do
    tournament = tournaments(:small_tournament)
    tournament.update!(address: "Nonexistent Place, Nowhere")

    # Mock empty API response with exact parameters and headers
    stub_request(:get, "https://nominatim.openstreetmap.org/search")
      .with(
        query: { "limit" => "1", "format" => "jsonv2", "q" => "Nonexistent Place, Nowhere" },
        headers: {
          "User-Agent" => "Canivete webapp backend",
          "Referrer" => "https://canivete.pt",
          "Content-Type" => "application/json; charset=UTF-8"
        }
      )
      .to_return(
        status: 200,
        body: JSON.generate([]),
        headers: { "Content-Type" => "application/json" }
      )

    # Should not raise an error
    assert_nothing_raised do
      Tournaments::GeocodeJob.perform_now(tournament)
    end

    # Location should remain nil
    tournament.reload
    assert_nil tournament.location
  end

  test "handles API errors gracefully" do
    tournament = tournaments(:small_tournament)
    tournament.update!(address: "Some Address")

    # Mock API error with exact parameters and headers
    stub_request(:get, "https://nominatim.openstreetmap.org/search")
      .with(
        query: { "limit" => "1", "format" => "jsonv2", "q" => "Some Address" },
        headers: {
          "User-Agent" => "Canivete webapp backend",
          "Referrer" => "https://canivete.pt",
          "Content-Type" => "application/json; charset=UTF-8"
        }
      )
      .to_return(status: 500, body: "Internal Server Error")

    # Should raise an error due to JSON parsing failure
    assert_raises(JSON::ParserError) do
      Tournaments::GeocodeJob.perform_now(tournament)
    end
  end

  test "job is queued with correct arguments" do
    tournament = tournaments(:small_tournament)

    assert_enqueued_with(job: Tournaments::GeocodeJob, args: [ tournament ]) do
      Tournaments::GeocodeJob.perform_later(tournament)
    end
  end

  test "job is queued with correct queue" do
    tournament = tournaments(:small_tournament)

    assert_enqueued_with(job: Tournaments::GeocodeJob, queue: "geocode") do
      Tournaments::GeocodeJob.perform_later(tournament)
    end
  end
end
