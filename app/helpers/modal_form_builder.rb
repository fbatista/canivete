# frozen_string_literal: true

class ModalFormBuilder < ActionView::Helpers::FormBuilder
  FIELD_CLASSES = {
    'file_field' => %w[
      block w-full cursor-pointer
      text-sm text-gray-900 dark:text-gray-400 dark:placeholder-gray-400
      border border-gray-300 rounded-lg focus:outline-none dark:border-gray-600
      bg-gray-50 dark:bg-gray-700
    ].join(' '),
    'check_box' => %w[
      w-4 h-4 border border-gray-300 rounded bg-gray-50
      focus:ring-3 focus:ring-blue-300
      dark:bg-gray-700 dark:border-gray-600
      dark:focus:ring-blue-600 dark:ring-offset-gray-800 dark:focus:ring-offset-gray-800
    ].join(' '),
    'text_area' => %w[
      block p-2.5 w-full text-sm text-gray-900 bg-gray-50 rounded-lg border border-gray-300
      focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600
      dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500
    ].join(' '),
    'default' => %w[
      bg-gray-50 border border-gray-300 text-gray-900
      text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full
      p-2.5 dark:bg-gray-600 dark:border-gray-500 dark:placeholder-gray-400 dark:text-white
      dark:focus:ring-blue-500 dark:focus:border-blue-500
    ].join(' ')
  }.freeze
  LABEL_CLASSES = %w[ms-2 text-sm font-medium text-gray-900 dark:text-gray-300].join(' ')
  WRAPPER_CLASSES = %w[flex flex-col gap-1 mb-4].join(' ')

  def method_missing(method_name, *args, &)
    return super unless method_name.to_s.end_with?('_with_label')

    original_method = method_name.to_s.chomp('_with_label')
    return super unless respond_to?(original_method)

    name, *rest = args
    options = rest.extract_options!
    label_html = label(name, { class: LABEL_CLASSES }.merge(options[:label] || {}))
    field_html = public_send(
      original_method, name,
      *(rest + [{ class: FIELD_CLASSES.fetch(original_method, FIELD_CLASSES['default']) }.merge(options)]), &
    )

    @template.content_tag(:div, class: WRAPPER_CLASSES) do
      @template.safe_join([label_html, field_html])
    end
  end

  def select(method, choices = nil, options = {}, html_options = {}, &)
    @template.select(
      @object_name, method, choices, objectify_options(options),
      @default_html_options.merge(class: FIELD_CLASSES['default']).merge(html_options), &
    )
  end

  def check_box_with_label(method, options = {}, checked_value = '1', unchecked_value = '0')
    label_html = label(method, options.dig(:label, :text), { class: LABEL_CLASSES }.merge(options[:label] || {}))
    check_box_html = check_box(
      method,
      objectify_options({ class: FIELD_CLASSES['check_box'] }.merge(options)),
      checked_value, unchecked_value
    )
    @template.content_tag(:div, class: 'flex items-start mb-5') do
      @template.safe_join(
        [
          @template.content_tag(:div, class: 'flex items-center h-5') { check_box_html },
          label_html
        ]
      )
    end
  end

  def submit(value = nil, options = {})
    if value.is_a?(Hash)
      options = value
      value = nil
    end
    value ||= submit_default_value
    @template.button_tag(
      value,
      {
        form: @options.dig(:html, :id),
        class: [
          'text-white', 'bg-blue-700', 'hover:bg-blue-800', 'focus:ring-4', 'focus:outline-none',
          'focus:ring-blue-300', 'font-medium', 'rounded-lg', 'text-sm', 'px-5', 'py-2.5', 'text-center',
          'dark:bg-blue-600', 'dark:hover:bg-blue-700', 'dark:focus:ring-blue-800'
        ].join(' ')
      }.merge(options)
    )
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.end_with?('_with_label') || super
  end
end
