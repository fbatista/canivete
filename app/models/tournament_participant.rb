class TournamentParticipant < ApplicationRecord
  belongs_to :tournament
  belongs_to :player

  has_many :results
  has_many :opponents, through: :results

  validates :decklist, presence: true

  def points
    
  end
end
