# frozen_string_literal: true

module ApplicationHelper
  RESULT_CLASSES = {
    Advance => 'bg-blue-100 text-blue-800 font-medium inline-flex items-center px-2.5 py-0.5 rounded dark:bg-gray-700 dark:text-blue-400 border border-blue-400',
    Win => 'bg-green-100 text-green-800 font-medium inline-flex items-center px-2.5 py-0.5 rounded dark:bg-gray-700 dark:text-green-400 border border-green-400',
    Penalty => 'bg-red-100 text-red-800 font-medium inline-flex items-center px-2.5 py-0.5 rounded dark:bg-gray-700 dark:text-red-400 border border-red-400',
    Loss => 'bg-gray-100 text-gray-800 font-medium inline-flex items-center px-2.5 py-0.5 rounded dark:bg-gray-700 dark:text-gray-400 border border-gray-500',
    Eliminated => 'bg-gray-100 text-gray-800 font-medium inline-flex items-center px-2.5 py-0.5 rounded dark:bg-gray-700 dark:text-gray-400 border border-gray-500',
    Draw => 'bg-yellow-100 text-yellow-800 font-medium inline-flex items-center px-2.5 py-0.5 rounded dark:bg-gray-700 dark:text-yellow-300 border border-yellow-300'
  }.freeze

  RESULT_ICONS = {
    Advance => 'fast-forward',
    Win => 'medal',
    Penalty => 'gavel',
    Loss => 'smiley-nervous',
    Eliminated => 'smiley-x-eyes',
    Draw => 'handshake'
  }

  def result_indicator(pod:, player:)
    result = pod.results.find { |r| r.tournament_participant_id == player.id }
    if result.instance_of?(Advance) && pod.present?
      tag.span(class: RESULT_CLASSES[Win]) do
        concat icon(pod.round.last_single_elimination_round? ? 'trophy' : 'medal', class: 'me-2')
        concat truncate(player.name)
      end
    else
      result_badge(result, player)
    end
  end

  def result_badge(result, player)
    tag.span(class: RESULT_CLASSES[result.class]) do
      concat icon(RESULT_ICONS[result.class], class: 'me-2')
      concat truncate(player.name)
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

  def current_player?(player)
    current_user&.player == player
  end
end
