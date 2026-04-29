# frozen_string_literal: true

class CircuitsController < ApplicationController
  skip_before_action :require_authentication

  def index
    @circuits = Circuit.includes(:events, :tournaments, :leagues, :event_organizer)
      .page(params[:page])
  end

  def show
    @circuit = Circuit.preload(
      events: :rounds,
      tournaments: :rounds,
      leagues: :rounds,
      circuit_standings: :player
    ).find(params[:id])
  end
end
