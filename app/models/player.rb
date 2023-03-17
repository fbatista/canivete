# frozen_string_literal: true

class Player < ApplicationRecord
  belongs_to :user, optional: true

  has_many :tournament_participations, class_name: 'TournamentParticipant'
  has_many :tournaments, through: :tournament_participations

  validates :key, presence: true
  delegate :name, to: :user
end
