# frozen_string_literal: true

class RoundsController < ApplicationController
  def index
    @rounds = load_tournament.rounds
  end

  def show
    @round = load_tournament.rounds.find params[:id]

    load_pods
    load_users_map
  end

  private

  def load_tournament
    Tournament.find params[:tournament_id]
  end

  def load_pods
    @pods = @round.pods.preload(seatings: { tournament_participant: { player: :user } })
  end

  def load_users_map
    @users_map = {}
    @pods.each do |p|
      p.seatings.each do |s|
        @users_map[s.tournament_participant_id] =
          { name: s.tournament_participant.name, pod: "Pod #{p.number}", seating: s.order.ordinalize }
      end
    end
  end
end
