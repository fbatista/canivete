# frozen_string_literal: true

module ApplicationHelper
  def result_indicator(pod:, player:)
    case pod.results.find { |result| result.tournament_participant_id == player.id }
    when Win
      'bg-green-500'
    when Penalty
      'bg-red-500'
    when Loss
      'bg-gray-500'
    when Draw
      'bg-yellow-500'
    end
  end
end
