# frozen_string_literal: true

class TournamentOrganizer < ApplicationRecord
  belongs_to :user, optional: true

  has_many :tournaments, dependent: :destroy

  delegate :name, to: :user
end
