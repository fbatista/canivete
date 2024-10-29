# frozen_string_literal: true

module Organizer
  class TournamentParticipantsController < OrganizerController
    layout 'modal'

    def index
      @tournament = load_tournament
      @layout_mode = 'modal'
      return unless params[:layout] == 'application'

      @layout_mode = 'application'
      render layout: 'application'
    end

    def new; end

    def create; end

    def update
      @tournament = load_tournament
      @tournament_participant = load_tournament_participant(@tournament)

      @tournament_participant.update(tournament_participant_params)

      redirect_to [:organizer, @tournament, :tournament_participants, { layout: 'application' }],
                  notice: "#{@tournament_participant.name} #{@tournament_participant.dropped? ? 'dropped' : 'updated'}!"
    end

    def destroy; end

    private

    def load_tournament
      Tournament.for_organizer(current_organizer).find params[:tournament_id]
    end

    def load_tournament_participant(tournament)
      tournament.tournament_participants.find(params[:id])
    end

    def tournament_participant_params
      params.require(:tournament_participant).permit(:dropped)
    end
  end
end
