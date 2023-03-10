class Seating < ApplicationRecord
  belongs_to :pod
  belongs_to :tournament_participant

  has_one :round, through: :pod

  validates :order, presence: true
end