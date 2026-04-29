# frozen_string_literal: true

class EventsController < ApplicationController
  skip_before_action :require_authentication

  def index
    @tournaments = Tournament
      .with_attached_cover
      .where.not(state: %i[draft canceled])
      .preload(:rounds)

    @leagues = League
      .with_attached_cover
      .where.not(state: %i[draft canceled])
      .preload(:rounds)

    case params[:filter]
    when "past"
      @tournaments = @tournaments.past
      @leagues = @leagues.past
      @title = "Past events"
    else
      @tournaments = @tournaments.upcoming
      @leagues = @leagues.upcoming
      @title = "Upcoming events"
    end

    @tournaments = @tournaments.page params[:page]
    @leagues = @leagues.page params[:page]

    @ongoing = Tournament.for_player(current_user&.player).ongoing +
               League.for_player(current_user&.player).ongoing
  end
end
