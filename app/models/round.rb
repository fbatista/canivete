class Round < ApplicationRecord
  belongs_to :tournament
  has_many :pods

  validates(
    :number,
    {
      presence: true,
      uniqueness: { scope: :tournament_id },
      numericality: true,
      inclusion: { in: 1.. }
    }
  )
end
