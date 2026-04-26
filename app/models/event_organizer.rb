# frozen_string_literal: true

class EventOrganizer < ApplicationRecord
  belongs_to :user, optional: true

  has_many :events, dependent: :destroy
  has_many :circuits, dependent: :destroy

  delegate :name, to: :user

  CURRENCIES = {
    euro: 0,
    dollar: 1
  }.freeze

  enum :default_currency, CURRENCIES
end
