class Tournament < ApplicationRecord
  has_many :rounds

  POD_SIZE = 4
  POINTS_PER_WIN = 5
  POINTS_PER_BYE = 5
  POINTS_PER_LOSS = 0
  POINTS_PER_DRAW = 1

  validates :name, presence: true
end
