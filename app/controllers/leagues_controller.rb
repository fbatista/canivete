# frozen_string_literal: true

class LeaguesController < ApplicationController
  skip_before_action :require_authentication

  def index
    scope = League.with_attached_cover.where.not(state: %i[draft canceled]).preload(:rounds)

    case params[:filter]
    when "past"
      scope = scope.past
      @title = "Past leagues"
    else
      scope = scope.upcoming
      @title = "Upcoming leagues"
    end

    @leagues = scope.page params[:page]

    @ongoing = League.for_player(current_user&.player).ongoing
  end

  def show
    @league = League.preload(rounds: :pods, event_participants: { player: :user }).find(params[:id])
  end
end
