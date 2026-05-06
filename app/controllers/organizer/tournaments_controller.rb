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
            event_participants: { player: :user }
          ).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to url_for(action: :index), alert: t("flash.alert.not_authorized_tournament")
    end

    def new
      @tournament = Tournament.new
    end

    def edit
      @tournament = Tournament.for_organizer(current_organizer).find params[:id]
    end

    def create
      @tournament = Tournament.create(
        tournament_params.merge(event_organizer: current_organizer)
      )

      redirect_to [:organizer, @tournament], notice: t("flash.notice.tournament_created")
    end

    def update
      @tournament = Tournament.for_organizer(current_organizer).find params[:id]
      @tournament.attributes = tournament_params

      if @tournament.save
        if @tournament.state_previously_changed? && @tournament.single_elimination?
          redirect_to [:organizer, @tournament, @tournament.rounds.max_by(&:number).becomes(Round)],
                      notice: t("flash.notice.tournament_advanced")
        else
          redirect_to [:organizer, @tournament], notice: t("flash.notice.tournament_updated")
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def tournament_params
      params.expect(tournament: %i[
                      name
                      state
                      description
                      start_time
                      end_time
                      minimum_participants
                      maximum_participants
                      prizes
                      address
                      schedule
                      rules
                      price
                      currency
                      cover
                    ])
    end
  end
end
