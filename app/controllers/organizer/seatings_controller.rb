# frozen_string_literal: true

module Organizer
  class SeatingsController < OrganizerController
    def swap
      tournament = load_tournament
      round = load_round(tournament)
      from_seating = load_seating(round, params[:player], params[:pod])
      to_seating = load_seating(round, params[:with_player], params[:with_pod])

      to_seating.tournament_participant_id, from_seating.tournament_participant_id =
        from_seating.tournament_participant_id, to_seating.tournament_participant_id

      Seating.transaction do
        to_seating.save!
        from_seating.save!
      end

      redirect_to [ :organizer, tournament, round.becomes(Round) ], notice: "Players Swapped!"
    end

    private

    def load_tournament
      Tournament.for_organizer(current_organizer).find params[:tournament_id]
    end

    def load_round(tournament)
      tournament.rounds.find params[:round_id]
    end

    def load_seating(round, player_id, pod_id)
      round.seatings.find_by(tournament_participant_id: player_id, pod_id:)
    end
  end
end
