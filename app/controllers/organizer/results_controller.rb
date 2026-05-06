# frozen_string_literal: true

module Organizer
  class ResultsController < OrganizerController
    def new
      @tournament = load_tournament
      @round = load_round(@tournament)
      @pod = load_pod(@round)
      @result = Result.new(round: @round)
    end

    def create
      @tournament = load_tournament
      @round = load_round(@tournament)
      @pod = load_pod(@round)
      event_participant = load_participant(@pod) if result_params[:event_participant_id].present?

      Events::SubmitResultJob.perform_now(
        type: result_params[:type],
        event_participant: event_participant, round: @round, pod: @pod
      )
      redirect_to [:organizer, @tournament, @round.becomes(Round)], notice: t("flash.notice.result_submitted")
    rescue StandardError => e
      redirect_to [:organizer, @tournament, @round.becomes(Round)], alert: e
    end

    private

    def load_tournament
      Tournament.for_organizer(current_organizer).find params[:tournament_id]
    end

    def load_round(tournament)
      tournament.rounds.find params[:round_id]
    end

    def load_pod(round)
      round.pods.find params[:pod_id]
    end

    def load_participant(pod)
      pod.event_participants.find result_params[:event_participant_id]
    end

    def result_params
      params.expect(result: [
                      :type,
                      :event_participant_id
                    ])
    end
  end
end
