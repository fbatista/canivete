# frozen_string_literal: true

class TournamentOrganizer < ApplicationRecord
  belongs_to :user, optional: true

  has_many :tournaments, dependent: :destroy

  delegate :name, to: :user

  CURRENCIES = {
    euro: 0,
    dollar: 1
  }.freeze

  enum :default_currency, CURRENCIES
end
