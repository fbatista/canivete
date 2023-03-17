# frozen_string_literal: true

class RoundsController < ApplicationController
  def index
    @rounds = load_tournament.rounds
  end

  def show
    @round = load_tournament.rounds.find params[:id]
  end

  private

  def load_tournament
    Tournament.find params[:tournament_id]
  end
end
