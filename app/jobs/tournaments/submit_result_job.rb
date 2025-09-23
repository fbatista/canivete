# frozen_string_literal: true

module Tournaments
  class SubmitResultJob < ApplicationJob
    def perform(type:, tournament_participant:, round:, pod:)
      load_instance_variables(type:, tournament_participant:, round:, pod:)
      handle_result
    end

    private

    def load_instance_variables(type:, tournament_participant:, round:, pod:)
      @type = type
      @tournament_participant = tournament_participant
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
      @pod.tournament_participants.reject { |tp| tp == @tournament_participant }.each do |tp|
        Result.create_or_update_by(round: @round, tournament_participant: tp) do |result|
          result.type = "Eliminated"
        end
      end
      Result.create_or_update_by(round: @round, tournament_participant: @tournament_participant) do |result|
        result.type = "Advance"
      end
    end

    def handle_win
      raise "Must select a winner" if @tournament_participant.blank?

      @pod.tournament_participants.reject { |tp| tp == @tournament_participant }.each do |tp|
        Result.create_or_update_by(round: @round, tournament_participant: tp) do |result|
          result.type = "Loss" unless result.type == "Penalty"
        end
      end
      Result.create_or_update_by(round: @round, tournament_participant: @tournament_participant) do |result|
        result.type = "Win"
      end
    end

    def handle_draw
      @pod.tournament_participants.each do |tournament_participant|
        Result.create_or_update_by(round: @round, tournament_participant:) do |result|
          result.type = "Draw" unless result.type == "Penalty"
        end
      end
    end

    def handle_penalty
      Result.create_or_update_by(round: @round, tournament_participant: @tournament_participant) do |result|
        result.type = "Penalty"
      end
    end
  end
end
