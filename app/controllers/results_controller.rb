# frozen_string_literal: true

class ResultsController < ApplicationController
  def new
    @tournament = load_tournament
    @round = load_round(@tournament)
    @pod = load_pod(@round)
    @result = Result.new(round: @round)
  end

  def create
    tournament = load_tournament
    round = load_round(tournament)
    pod = load_pod(round)
    tournament_participant = load_participant(pod) if result_params[:tournament_participant_id].present?

    Tournaments::SubmitResultJob.perform_now(
      type: result_params[:type],
      tournament_participant:, round:, pod:
    )

    redirect_to [tournament, round.becomes(Round)], notice: 'Result submitted successfully'
  end

  private

  def load_tournament
    Tournament.find params[:tournament_id]
  end

  def load_round(tournament)
    tournament.rounds.find params[:round_id]
  end

  def load_pod(round)
    round.pods.find params[:pod_id]
  end

  def load_participant(pod)
    pod.tournament_participants.find result_params[:tournament_participant_id]
  end

  def result_params
    params.require(:result).permit(
      :type,
      :tournament_participant_id
    )
  end
end
