class Tournament < ApplicationRecord
  has_many :rounds, dependent: :destroy

  POD_SIZE = 4
  POINTS_PER_WIN = 5
  POINTS_PER_BYE = 5
  POINTS_PER_LOSS = 0
  POINTS_PER_DRAW = 1

  enum :state, [:registration, :swiss, :single_elimination, :finished], default: :registration

  validates :name, presence: true
end
