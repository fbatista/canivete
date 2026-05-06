# frozen_string_literal: true

class RoundsController < ApplicationController
  skip_before_action :require_authentication, only: %i[index show]
  def index
    @rounds = load_event.rounds
  end

  def show
    event = load_event
    @round = load_round(event)
    @pods = load_pods(@round)
    @users_map = load_users_map(@pods)

    return if params[:query].blank?

    @users_map.filter! { |_, v| v[:name].downcase.include?(params[:query].downcase) }
  end

  def update
    event = load_event
    @round = load_round(event)

    case round_params[:action]
    when "start"
      @round.update(started_at: Time.zone.now)
      redirect_to [@round.event, @round.becomes(Round)], notice: t("flash.notice.round_started")
    when "finish"
      @round.update(finished_at: Time.zone.now)
      redirect_to event, notice: t("flash.notice.round_finished")
    end
  end

  private

  def round_params
    params.expect(round: [:action])
  end

  def load_event
    Tournament.find params[:tournament_id]
  end

  def load_round(event)
    event.rounds.find params[:id]
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
          seating: s.order.ordinalize
        }
      end
    end
    users_map
  end
end
