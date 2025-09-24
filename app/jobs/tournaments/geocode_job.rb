# frozen_string_literal: true

require "net/http"

module Tournaments
  class GeocodeJob < ApplicationJob
    queue_as :geocode
    limits_concurrency key: ->(_) { "GeocodeJob" }

    def perform(tournament)
      # Ensure at least 1 second between API calls
      sleep(1)
      # Geocode the address using Nominatim
      point = geocode_address(tournament.address)

      return unless point

      # Update the tournament with the geocoded location
      tournament.update!(location: point)
    end

    private

    def geocode_address(address)
      response = request_openstreet(address)&.first&.with_indifferent_access
      return nil unless response
      response => { lat:, lon: }
      return nil unless lat && lon

      RGeo::Geographic.spherical_factory(srid: 4326).point(
        lon&.to_f,
        lat&.to_f
      )
    end

    def request_openstreet(address)
      uri = URI("https://nominatim.openstreetmap.org/search")
      params = { limit: 1, format: "jsonv2", q: address }
      uri.query = URI.encode_www_form(params)
      headers = {
        "User-Agent" => "Canivete webapp backend",
        "Referrer" => "https://canivete.pt",
        "Content-type" => "application/json; charset=UTF-8"
      }

      response = Net::HTTP.get(uri, headers)
      JSON.parse(response)
    end
  end
end
