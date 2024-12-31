# frozen_string_literal: true

module TournamentsHelper
  CURRENCY_SYMBOLS = {
    euro: '€',
    dollar: '$'
  }.with_indifferent_access.freeze

  NUMBER_CURRENCY_OPTIONS = {
    euro: { unit: '€', separator: ',', delimiter: ' ', format: '%n %u' },
    dollar: {}
  }.with_indifferent_access.freeze

  STATE_TRANSITION_MAP = {
    draft: { name: 'Make Draft', icon: 'pencil' },
    registration_open: { name: 'Open Registrations', icon: 'megaphone' },
    registration_closed: { name: 'Close Registrations', icon: 'lock' },
    swiss: { name: 'Move to Swiss stage', icon: 'ranking' },
    single_elimination: { name: 'Move to Single Elimination Stage', icon: 'tree-structure' },
    finished: { name: 'Finish', icon: 'trophy' },
    canceled: { name: 'Cancel', icon: 'trash' }
  }.with_indifferent_access.freeze

  def currency_options
    TournamentOrganizer::CURRENCIES.keys.map { |c| [CURRENCY_SYMBOLS[c], c] }
  end

  def number_to_currency_options(currency)
    NUMBER_CURRENCY_OPTIONS[currency]
  end

  def map_embed_url(tournament)
    uri = URI('https://maps.google.com/maps')
    params = {
      q: "#{tournament.latitude}, #{tournament.longitude}(#{tournament.address})",
      hl: 'en', z: 14, ie: 'UTF8', iwloc: 'B', output: 'embed'
    }
    uri.query = URI.encode_www_form(params)
    uri
  end

  def transition_for(state:)
    tag.span(class: 'inline-flex items-center') do
      concat icon(STATE_TRANSITION_MAP[state][:icon], class: 'me-2')
      concat STATE_TRANSITION_MAP[state][:name]
    end
  end
end
