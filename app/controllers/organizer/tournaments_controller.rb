# frozen_string_literal: true

module Organizer
  class TournamentsController < OrganizerController
    def index
      @tournaments = Tournament.all.for_organizer(current_organizer)
    end

    def new
      @tournament = Tournament.new
    end

    def create
      @tournament = Tournament.create(
        tournament_params.merge(tournament_organizer: current_organizer)
      )

      redirect_to @tournament, notice: 'Tournament created successfully'
    end

    def show
      @tournament =
        Tournament
        .for_organizer(current_organizer)
        .preload(
          rounds: :pods,
          tournament_participants: { player: :user }
        ).find(params[:id])
    end

    def edit
      @tournament = Tournament.for_organizer(current_organizer).find params[:id]
    end

    def update
      @tournament = Tournament.for_organizer(current_organizer).find params[:id]
      @tournament.attributes = tournament_params

      if @tournament.save
        redirect_to @tournament, notice: 'Tournament updated successfully'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def tournament_params
      params.require(:tournament).permit(
        :name,
        :state
      )
    end
  end
end
