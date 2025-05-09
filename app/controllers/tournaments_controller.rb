# frozen_string_literal: true

class TournamentsController < ApplicationController
  skip_before_action :require_authentication
  def index
    scope = Tournament.where.not(state: %i[draft canceled])

    case params[:filter]
    when "past"
      scope = scope.past
      @title = "Past tournaments"
    else
      scope = scope.upcoming
      @title = "Upcoming tournaments"
    end

    @tournaments = scope.page params[:page]

    @ongoing = Tournament.for_player(current_user&.player).ongoing
  end

  def show
    @tournament = Tournament.preload(rounds: :pods, tournament_participants: { player: :user }).find(params[:id])
  end
end
