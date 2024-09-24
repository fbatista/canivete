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

  def currency_options
    TournamentOrganizer::CURRENCIES.keys.map { |c| [CURRENCY_SYMBOLS[c], c] }
  end

  def number_to_currency_options(currency)
    NUMBER_CURRENCY_OPTIONS[currency]
  end
end
