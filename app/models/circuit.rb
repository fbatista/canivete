# frozen_string_literal: true

class Circuit < ApplicationRecord
  has_many :tournaments, dependent: :nullify
  belongs_to :event_organizer
end
