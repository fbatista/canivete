# frozen_string_literal: true

module Organizer
  class TournamentsController < OrganizerController
    def index
      @tournaments = Tournament.with_attached_cover.where.not(state: :canceled).for_organizer(current_organizer).preload(:rounds)
    end

    def show
      @tournament =
        Tournament
        .for_organizer(current_organizer)
        .preload(
          rounds: :pods,
          tournament_participants: { player: :user }
        ).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to url_for(action: :index), alert: "Not authorized to manage the selected tournament"
    end

    def new
      @tournament = Tournament.new
    end

    def edit
      @tournament = Tournament.for_organizer(current_organizer).find params[:id]
    end

    def create
      @tournament = Tournament.create(
        tournament_params.merge(tournament_organizer: current_organizer)
      )

      redirect_to [ :organizer, @tournament ], notice: "Tournament created successfully"
    end

    def update
      @tournament = Tournament.for_organizer(current_organizer).find params[:id]
      @tournament.attributes = tournament_params

      if @tournament.save
        if @tournament.state_previously_changed? && @tournament.single_elimination?
          redirect_to [ :organizer, @tournament, @tournament.rounds.max_by(&:number).becomes(Round) ],
                      notice: "Tournament advanceded!"
        else
          redirect_to [ :organizer, @tournament ], notice: "Tournament updated successfully"
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def tournament_params
      params.expect(tournament: [
        :name,
        :state,
        :description,
        :start_time,
        :end_time,
        :minimum_participants,
        :maximum_participants,
        :prizes,
        :address,
        :schedule,
        :rules,
        :price,
        :currency,
        :cover
      ])
    end
  end
end
