# frozen_string_literal: true

module Events
  class SubmitResultJob < ApplicationJob
    def perform(type:, event_participant:, round:, pod:)
      load_instance_variables(type: type, event_participant: event_participant, round: round, pod: pod)
      handle_result

      recalculate_league_scores if @round.event.is_a?(League) && @round.event.play?
    end

    def recalculate_league_scores
      Scoring::PointWager.new(@round.event).recalculate_all!
    end

    private

    def load_instance_variables(type:, event_participant:, round:, pod:)
      @type = type
      @event_participant = event_participant
      @round = round
      @pod = pod
    end

    def handle_result
      Result.transaction do
        case @type
        when "Advance"
          handle_advance
        when "Win"
          handle_win
        when "Draw"
          handle_draw
        when "Penalty"
          handle_penalty
        end
      end
    end

    def handle_advance
      @pod.event_participants.reject { |tp| tp == @event_participant }.each do |tp|
        Result.create_or_update_by(round: @round, event_participant: tp) do |result|
          result.type = "Eliminated"
        end
      end
      Result.create_or_update_by(round: @round, event_participant: @event_participant) do |result|
        result.type = "Advance"
      end
    end

    def handle_win
      raise "Must select a winner" if @event_participant.blank?

      @pod.event_participants.reject { |tp| tp == @event_participant }.each do |tp|
        Result.create_or_update_by(round: @round, event_participant: tp) do |result|
          result.type = "Loss" unless result.type == "Penalty"
        end
      end
      Result.create_or_update_by(round: @round, event_participant: @event_participant) do |result|
        result.type = "Win"
      end
    end

    def handle_draw
      @pod.event_participants.each do |event_participant|
        Result.create_or_update_by(round: @round, event_participant: event_participant) do |result|
          result.type = "Draw" unless result.type == "Penalty"
        end
      end
    end

    def handle_penalty
      Result.create_or_update_by(round: @round, event_participant: @event_participant) do |result|
        result.type = "Penalty"
      end
    end
  end
end
