# frozen_string_literal: true

module Organizer
  class RoundsController < OrganizerController
    def show
      event = load_tournament
      @round = load_round(event)
      @pods = load_pods(@round)
      @users_map = load_users_map(@pods)

      return if params[:query].blank?

      @users_map.filter! { |_, v| v[:name].downcase.include?(params[:query].downcase) }
    end

    def update
      event = load_tournament
      @round = load_round(event)

      case round_params[:action]
      when "publish"
        @round.update(published: true)
        redirect_to [:organizer, @round.event, @round.becomes(Round)], notice: "Round Published!"
      when "start"
        @round.update(started_at: Time.zone.now)
        redirect_to [:organizer, @round.event, @round.becomes(Round)], notice: "Round Started!"
      when "finish"
        @round.update(finished_at: Time.zone.now)
        redirect_to [:organizer, event, event.rounds.max_by(&:number).becomes(Round)],
                    notice: "Round Finished!"
      end
    end

    def destroy
      event = load_tournament
      load_round(event).destroy
      event.rounds.max_by(&:number).update(finished_at: nil)

      if event.single_elimination? && event.rounds.none?(SingleEliminationRound)
        event.update(state: :swiss)
      end

      redirect_to [:organizer, event, event.rounds.max_by(&:number).becomes(Round)],
                  notice: "Ongoing round destroyed, rolled back previous round to unfinished!"
    end

    private

    def round_params
      params.expect(round: [:action])
    end

    def load_tournament
      Tournament.for_organizer(current_organizer).find params[:tournament_id]
    end

    def load_round(tournament)
      tournament.rounds.find params[:id]
    end

    def load_pods(round)
      round.pods.preload(seatings: { event_participant: { player: :user } })
    end

    def load_users_map(pods)
      users_map = {}
      pods.each do |p|
        p.seatings.each do |s|
          users_map[s.event_participant_id] = {
            tp: s.event_participant,
            name: s.event_participant.name,
            pod: "Pod #{p.number}",
            pod_id: p.id,
            seating: s.order.ordinalize
          }
        end
      end
      users_map
    end
  end
end
