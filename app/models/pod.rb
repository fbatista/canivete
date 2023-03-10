class Pod < ApplicationRecord
  belongs_to :round
  has_one :tournament, through: :round

  has_many :seatings
  has_many :tournament_participants, through: :seatings
  has_many :players, through: :tournament_participants

  validates(
    :number,
    {
      presence: true,
      uniqueness: { scope: :round_id },
      numericality: true,
      inclusion: { in: 1.. }
    }
  )
end
