# frozen_string_literal: true

module Organizer
  class PenaltiesController < OrganizerController
    layout 'modal'
    def index
      tournament_participant = TournamentParticipant.find(params[:tournament_participant_id])
      @penalties = Penalty.where(
        player_id: tournament_participant.player_id,
        tournament_id: tournament_participant.tournament_id
      )
    end

    def new
      player = load_player
      pod = load_pod
      tournament = @pod&.tournament || load_tournament
      @penalty = Penalty.new(player:, pod:, tournament:)
    end

    def create
      @penalty = Penalty.new(tournament: load_tournament)
      @penalty.attributes = penalty_params

      if @penalty.save
        redirect_to [:organizer, @penalty.tournament, :tournament_participants, { layout: 'application' }],
                    notice: 'Penalty added successfully'
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def penalty_params
      params.require(:penalty).permit(:player_id, :pod_id, :kind, :category, :description)
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
