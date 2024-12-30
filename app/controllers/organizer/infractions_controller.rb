# frozen_string_literal: true

module Organizer
  class InfractionsController < OrganizerController
    layout 'modal'
    def index
      @tournament_participant = TournamentParticipant.find(params[:tournament_participant_id])
      @infractions = Infraction.where(
        player_id: @tournament_participant.player_id,
        tournament_id: @tournament_participant.tournament_id
      )
    end

    def new
      player = load_player
      pod = load_pod
      tournament = pod&.tournament || load_tournament
      @infraction = Infraction.new(player:, pod:, tournament:)
    end

    def create
      @infraction = Infraction.new(tournament: load_tournament)
      @infraction.attributes = infraction_params

      if @infraction.save
        redirect_to [:organizer, @infraction.tournament, :tournament_participants, { layout: 'application' }],
                    notice: 'Infraction added successfully'
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def infraction_params
      params.require(:infraction).permit(:player_id, :pod_id, :kind, :category, :description, :penalty)
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
