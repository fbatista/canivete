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

  def badge(color:, &)
    tag.span(class: %w[
      text-xs font-medium me-2 px-2.5 py-0.5 rounded
    ] + [
      "bg-#{color}-100", "text-#{color}-800",
      "dark:bg-#{color}-900", "dark:text-#{color}-300"
    ], &)
  end

  def icon(name)
    tag.i(class: "ph-bold ph-#{name}")
  end

  def organizer_mode?
    url_for(controller: params[:controller], action: params[:action]).starts_with?('/organizer')
  end

  def organizer_path_builder # rubocop:disable Metrics/AbcSize
    if organizer_mode?
      begin
        url_for(params.dup.tap { |p| p[:controller] = p[:controller].gsub('organizer', '') }.permit!)
      rescue ActionController::UrlGenerationError
        url_for(:tournaments)
      end
    else
      begin
        url_for(params.dup.tap { |p| p[:controller] = "organizer/#{p[:controller]}" }.permit!)
      rescue ActionController::UrlGenerationError
        url_for(%i[organizer tournaments])
      end
    end
  end
end
