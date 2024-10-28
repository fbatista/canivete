# frozen_string_literal: true

class TournamentsController < ApplicationController
  def index
    @tournaments = Tournament.all
    current_user.player.tournaments.where(tournaments: { id: @tournaments })
  end

  def show
    @tournament = Tournament.preload(rounds: :pods, tournament_participants: { player: :user }).find(params[:id])
  end
end
