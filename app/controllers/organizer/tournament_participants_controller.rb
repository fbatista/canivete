# frozen_string_literal: true

module Organizer
  class TournamentParticipantsController < OrganizerController
    def index
      @tournament = load_tournament
    end

    def create
    end

    def destroy
    end

    private

    def load_tournament
      Tournament.for_organizer(current_organizer).find params[:tournament_id]
    end
  end
end
