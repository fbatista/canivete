# frozen_string_literal: true

class Player < ApplicationRecord
  belongs_to :user, optional: true

  has_many :tournament_participations, class_name: 'TournamentParticipant', dependent: :destroy
  has_many :tournaments, through: :tournament_participations
  has_many :penalties, dependent: :destroy

  validates :key, presence: true
  delegate :name, to: :user

  def participant?(tournament)
    tournament_participations.any? { |tp| tp.tournament_id == tournament.id }
  end

  def participant(tournament)
    tournament_participations.find { |tp| tp.tournament_id == tournament.id }
  end
end
