# frozen_string_literal: true

module Organizer
  class TournamentParticipantsController < OrganizerController
    layout "modal"

    def index
      @tournament = load_tournament

      case @tournament.state
      when "registration_open", "registration_closed"
        @tournament_participants = @tournament.tournament_participants.includes(player: :user).joins(player: :user).order(:name)
      else
        @tournament_participants = @tournament.tournament_participants.sort_by do |p|
          [
            p.playing? ? 0 : 1,
            -p.rank_score,
            -p.times_going_at(4),
            -p.times_going_at(3),
            -p.times_going_at(2),
            -p.times_going_at(1),
            p.name
          ]
        end
        @tournament_participants.each.with_index do |p, i|
          p.rank = i+1
        end
      end

      if params[:query].present?
        @tournament_participants = @tournament_participants.select { |p| p.name.downcase.include?(params[:query].downcase) }
      end

      @layout_mode = "modal"
      return unless params[:layout] == "application"

      @layout_mode = "application"
      render layout: "application"
    end

    def new
      @tournament_participant = TournamentParticipant.new(tournament: load_tournament)
    end

    def create
      @tournament_participant = TournamentParticipant.new(tournament: load_tournament)
      @tournament_participant.attributes = tournament_participant_params

      @tournament_participant.save

      redirect_to [ :organizer, @tournament_participant.tournament, :tournament_participants, { layout: "application" } ],
                  notice: "#{@tournament_participant.name} added!"
    end

    def update
      @tournament = load_tournament
      @tournament_participant = load_tournament_participant(@tournament)

      @tournament_participant.update(tournament_participant_params)
      # TODO: stay in place or fix the updated item
      redirect_to [ :organizer, @tournament, :tournament_participants, { layout: "application" } ],
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
      params.require(:tournament_participant).permit(
        :dropped,
        :checked_in,
        :paid,
        :player_email,
        :player_name,
        :decklist
      )
    end
  end
end
