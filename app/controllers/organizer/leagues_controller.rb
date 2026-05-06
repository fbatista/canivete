# frozen_string_literal: true

module Organizer
  class LeaguesController < OrganizerController
    def index
      @leagues = League
        .with_attached_cover
        .where.not(state: :canceled)
        .for_organizer(current_organizer)
        .preload(:rounds)
    end

    def show
      @league = League.for_organizer(current_organizer).preload(
        rounds: :pods,
        event_participants: { player: :user }
      ).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to [:organizer, :leagues], alert: t("flash.alert.not_authorized_league")
    end

    def new
      @league = League.new
    end

    def edit
      @league = League.for_organizer(current_organizer).find params[:id]
    end

    def create
      @league = League.create!(
        league_params.merge(event_organizer: current_organizer)
      )

      redirect_to [:organizer, @league], notice: t("flash.notice.league_created")
    rescue ActiveRecord::RecordInvalid => e
      @league = League.new(league_params.merge(event_organizer: current_organizer))
      @league.errors.add(:base, e.message)
      render :new, status: :unprocessable_entity
    end

    def update
      @league = League.for_organizer(current_organizer).find(params[:id])
      @league.attributes = league_params

      if @league.save
        if @league.state_previously_changed?
          @league.perform_state_based_actions
        end

        redirect_to [:organizer, @league], notice: t("flash.notice.league_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def create_pickup_pod
      @league = League.for_organizer(current_organizer).find(params[:id])
      Leagues::CreatePickupPodJob.perform_now(@league)
      redirect_to [:organizer, @league], notice: t("flash.notice.pickup_pod_created")
    rescue ActiveRecord::RecordNotFound
      redirect_to [:organizer, :leagues], alert: t("flash.alert.not_authorized_league")
    end

    private

    def league_params
      params.expect(
        league: %i[
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
          wager_percentage
          play_mode
          circuit_id
          cover
        ]
      )
    end
  end
end
