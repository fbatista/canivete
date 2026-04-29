# frozen_string_literal: true

module Tournaments
  class UnevenPodGenerator
    def initialize(round)
      @round = round
    end

    def generate_pods!
      build_pods(**calculate_number_of_pods)
    end

    private

    def calculate_number_of_pods # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      if @round.event_participants.size == @round.event.class::LARGER_POD_SIZE
        return { large: 1, preferred: 0, small: 0 }
      end

      preferred = @round.event_participants.size / @round.event.class::PREFERRED_POD_SIZE
      remaining_players = @round.event_participants.size % @round.event.class::PREFERRED_POD_SIZE

      if remaining_players.positive?
        preferred -= @round.event.class::SMALLER_POD_SIZE - remaining_players
        remaining_players += (@round.event.class::SMALLER_POD_SIZE - remaining_players) *
                             @round.event.class::PREFERRED_POD_SIZE
      end

      { large: 0, preferred: preferred, small: remaining_players / @round.event.class::SMALLER_POD_SIZE }
    end

    def build_pods(large:, preferred:, small:)
      i = 0
      large.times do
        @round.pods.build(number: i += 1, size: @round.event.class::LARGER_POD_SIZE)
      end
      preferred.times do
        @round.pods.build(number: i += 1, size: @round.event.class::PREFERRED_POD_SIZE)
      end
      small.times do
        @round.pods.build(number: i += 1, size: @round.event.class::SMALLER_POD_SIZE)
      end
    end
  end
end
