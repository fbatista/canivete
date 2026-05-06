# frozen_string_literal: true

module Organizer
  class InfractionsController < OrganizerController
    layout "modal"
    def index
      @event_participant = EventParticipant.find(params[:event_participant_id])
      @infractions = Infraction.where(
        player_id: @event_participant.player_id,
        event_id: @event_participant.event_id
      )
    end

    def new
      player = load_player
      pod = load_pod
      event = pod&.event || load_tournament
      @infraction = Infraction.new(player: player, pod: pod, event: event)
    end

    def create
      @infraction = Infraction.new(event: load_tournament)
      @infraction.attributes = infraction_params

      if @infraction.save
        redirect_to [:organizer, @infraction.event, :event_participants, { layout: "application" }],
                    notice: t("flash.notice.infraction_added")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      event = load_tournament
      event_participant = event.event_participants.includes(:player).find(
        params[:event_participant_id]
      )
      @infraction = Infraction.find_by(event: event, player: event_participant.player, id: params[:id])
      message =
        if @infraction.destroy
          { notice: "Infraction removed!" }
        else
          { alert: "Error removing infraction!" }
        end

      redirect_to [:organizer, @infraction.event, :event_participants, { layout: "application" }], **message
    end

    private

    def infraction_params
      params.expect(infraction: %i[player_id pod_id kind category description penalty])
    end

    def load_player
      Player.find(params[:player_id])
    end

    def load_pod
      Pod.where(id: params[:pod_id]).first
    end

    def load_tournament
      Tournament.where(id: params[:tournament_id]).first
    end
  end
end
