# frozen_string_literal: true

module Scoring
  class PointWager
    STARTING_POINTS = 1000

    def initialize(event)
      @event = event
      @wager_pct = event.wager_percentage || 0
    end

    # Calculate all league scores after any change (full recalc)
    def recalculate_all!
      regular_scores = compute_scores(direction: :forward)
      reverse_scores = compute_scores(direction: :reverse)

      @event.event_participants.playing.each do |ep|
        avg = ((regular_scores[ep.id] || STARTING_POINTS) +
               (reverse_scores[ep.id] || STARTING_POINTS)).fdiv(2)
        ep.update!(league_score: avg)
      end
    end

    private

    attr_reader :event, :wager_pct

    def compute_scores(direction:)
      results = event.rounds.play_rounds.order(number: :asc)
      results = results.reverse if direction == :reverse

      scores = {}
      event.event_participants.playing.each { |ep| scores[ep.id] = STARTING_POINTS }

      results.each do |round|
        round.pods.finished.each { |pod| apply_pod_result(pod, scores) }
      end

      scores
    end

    def apply_pod_result(pod, scores)
      participants = pod.event_participants
      return if participants.empty?

      participant_results = participants.index_with do |ep|
        ep.results.find { |r| r.round_id == pod.round_id }
      end

      wins = participant_results.select { |_, r| r&.is_a?(Win) }.keys
      draws = participant_results.select { |_, r| r&.is_a?(Draw) }.keys

      if wins.any? && draws.empty? && wins.size == 1
        # Single winner takes all wagers
        winner = wins.first
        pot = participants.sum { |ep| wager_amount(scores[ep.id]) }
        participants.each { |ep| scores[ep.id] -= wager_amount(scores[ep.id]) }
        scores[winner.id] += pot
      elsif draws.size == participants.size
        # All draw — split evenly
        pot = participants.sum { |ep| wager_amount(scores[ep.id]) }
        per_person = pot.fdiv(participants.size)
        participants.each { |ep| scores[ep.id] = per_person }
      end
    end

    def wager_amount(current_points)
      (current_points * wager_pct / 100).round(2)
    end
  end
end
