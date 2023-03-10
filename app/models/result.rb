class Result < ApplicationRecord
  belongs_to :tournament_participant
  belongs_to :round
  
  has_one :tournament, through: :round
  has_one :pod, ->(result) { joins(:tournament_participants).where(tournament_participants: { id: result.tournament_participant_id }).first } through: :round, source: :pods
  has_many :opponents, ->(result) { where.not id: result.tournament_participant_id }, through: :pod, class_name: "TournamentParticipant", source: :tournament_participants
end
