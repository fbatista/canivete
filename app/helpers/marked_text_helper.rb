# frozen_string_literal: true

module MarkedTextHelper
  include ActionView::Helpers::SanitizeHelper

  def marksmithed(text)
    return if text.blank?

    sanitized = sanitize(text, tags: %w[strong em a code pre])
    Commonmarker.to_html(sanitized, options: {
      parse: { smart: true },
      render: {},
      extension: {}
    }, plugins: {}).html_safe # rubocop:disable Rails/OutputSafety
  end
end
