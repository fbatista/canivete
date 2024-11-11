# frozen_string_literal: true

class TournamentsController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    scope = Tournament.all

    case params[:filter]
    when 'past'
      scope = scope.past
      @title = 'Past tournaments'
    else
      scope = scope.upcoming
      @title = 'Upcoming tournaments'
    end

    @tournaments = scope
  end

  def show
    @tournament = Tournament.preload(rounds: :pods, tournament_participants: { player: :user }).find(params[:id])
  end
end
