# frozen_string_literal: true

module ApplicationHelper
  def result_indicator(pod:, player:) # rubocop:disable Metrics/MethodLength
    case pod.results.find { |result| result.tournament_participant_id == player.id }
    when Advance
      'bg-blue-500 text-white'
    when Win
      'bg-green-600 text-white'
    when Penalty
      'bg-red-500 text-gray-800'
    when Loss, Eliminated
      'bg-gray-400 text-gray-800'
    when Draw
      'bg-yellow-500'
    end
  end
end
