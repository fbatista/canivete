# frozen_string_literal: true

class RoundsController < ApplicationController
  def index
    @rounds = load_tournament.rounds
  end

  def show
    tournament = load_tournament
    @round = load_round(tournament)
    @pods = load_pods(@round)
    @users_map = load_users_map(@pods)
  end

  def update
    tournament = load_tournament
    @round = load_round(tournament)

    case round_params[:action]
    when 'start'
      @round.update(started_at: Time.zone.now)
      redirect_to [@round.tournament, @round.becomes(Round)], notice: 'Round Started!'
    when 'finish'
      @round.update(finished_at: Time.zone.now)
      redirect_to tournament, notice: 'Round Finished!'
    end
  end

  private

  def round_params
    params.require(:round).permit(:action)
  end

  def load_tournament
    Tournament.find params[:tournament_id]
  end

  def load_round(tournament)
    tournament.rounds.find params[:id]
  end

  def load_pods(round)
    round.pods.preload(seatings: { tournament_participant: { player: :user } })
  end

  def load_users_map(pods)
    users_map = {}
    pods.each do |p|
      p.seatings.each do |s|
        users_map[s.tournament_participant_id] = {
          tp: s.tournament_participant,
          name: s.tournament_participant.name,
          pod: "Pod #{p.number}",
          seating: s.order.ordinalize
        }
      end
    end
    users_map
  end
end
