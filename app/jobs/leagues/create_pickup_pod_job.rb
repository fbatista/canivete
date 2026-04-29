# frozen_string_literal: true

module Leagues
  # Job to create a pick-up play pod for a league.
  # Groups available (playing, unseated) event participants into pods of 3-5 players.
  class CreatePickupPodJob < ApplicationJob
    def perform(league)
      @league = league
      return unless can_create_pod?

      round = ensure_play_round
      participants = available_participants(round)
      return if participants.empty?

      pod = create_pod_with_available_players(round)
      pod.sit_participants! if pod.persisted?
    end

    private

    attr_reader :league

    def can_create_pod?
      league.play? && league.event_participants.playing.count >= league.class::SMALLER_POD_SIZE
    end

    def ensure_play_round
      league.rounds.find_by(is_play_round: true, published: false) ||
        league.rounds.create!(
          type: SwissRound,
          number: league.rounds.size + 1,
          is_play_round: true
        )
    end

    def available_participants(round)
      seated_participant_ids = round.pods.flat_map(&:event_participant_ids).compact

      league.event_participants.playing
        .where.not(id: seated_participant_ids)
        .limit(league.class::PREFERRED_POD_SIZE)
    end

    def create_pod_with_available_players(round)
      participants = available_participants(round)

      Pod.create!(round: round, number: round.pods.size + 1).tap do |pod|
        participants.each_with_index do |participant, index|
          pod.seatings.build(event_participant: participant, order: index + 1)
        end
      end
    end
  end
end
