# frozen_string_literal: true

class Round < ApplicationRecord
  belongs_to :tournament
  has_many :pods, dependent: :destroy

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
