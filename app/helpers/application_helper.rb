# frozen_string_literal: true

module ApplicationHelper
  RESULT_CLASSES = {
    Advance => 'bg-blue-500 text-white dark:text-white',
    Win => 'bg-green-600 text-white dark:text-white',
    MatchLossPenalty => 'bg-red-500 text-gray-800 dark:text-gray-800',
    Loss => 'bg-gray-400 text-gray-800 dark:text-gray-800',
    Eliminated => 'bg-gray-400 text-gray-800 dark:text-gray-800',
    Draw => 'bg-yellow-400 text-black dark:text-black'
  }.freeze

  def result_indicator(pod:, player:)
    result = pod.results.find { |r| r.tournament_participant_id == player.id }
    RESULT_CLASSES[result.class]
  end

  def badge(color:, &)
    tag.span(class: %w[
      text-xs font-medium me-2 px-2.5 py-0.5 rounded
    ] + [
      "bg-#{color}-100", "text-#{color}-800",
      "dark:bg-#{color}-900", "dark:text-#{color}-300"
    ], &)
  end

  def icon(name, options = nil)
    css_classes = options&.dig(:class)
    tag.i(class: "ph-bold ph-#{name} #{css_classes}")
  end

  def organizer_mode?
    url_for(controller: params[:controller], action: params[:action]).starts_with?('/organizer')
  end

  def organizer_path_builder
    path = params.dup.tap do |p|
      p[:controller] = organizer_mode? ? p[:controller].gsub('organizer', '') : "organizer/#{p[:controller]}"
    end

    url_for(path.permit!)
  rescue ActionController::UrlGenerationError
    url_for(organizer_mode? ? :tournaments : %i[organizer tournaments])
  end

  def modal_form_for(record, options = {}, &)
    options[:builder] = ModalFormBuilder
    form_for(record, options, &)
  end

  def markdown(text)
    sanitized_text = sanitize(text, tags: %w[strong em a code pre], attributes: %w[href])

    Commonmarker.to_html(
      sanitized_text || '', options: {
        parse: { smart: true }
      }
    )
  end
end
