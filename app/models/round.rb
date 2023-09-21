# frozen_string_literal: true

class Round < ApplicationRecord
  belongs_to :tournament, counter_cache: true
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

  after_create :create_pods

  def create_pods
    Tournaments::CreatePodsJob.perform_now(self)
  end
end
