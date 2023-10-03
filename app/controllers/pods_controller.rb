# frozen_string_literal: true

class PodsController < ApplicationController
  def index
    tournament = load_tournament
    round = load_round(tournament)
    @pods = round.pods
  end

  def show
    tournament = load_tournament
    round = load_round(tournament)
    @pod = load_pod(round)
    @result = round.results.build
  end

  private

  def load_tournament
    Tournament.find params[:tournament_id]
  end

  def load_round(tournament)
    tournament.rounds.find params[:round_id]
  end

  def load_pod(round)
    round.pods.find(params[:id])
  end
end
