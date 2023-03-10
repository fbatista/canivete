class Seating < ApplicationRecord
  belongs_to :pod
  belongs_to :tournament_participant

  validates :order, presence: true
end