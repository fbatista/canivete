# frozen_string_literal: true

class Result < ApplicationRecord
  belongs_to :tournament_participant
  belongs_to :round

  has_one :tournament, through: :round

  SELECTABLE_SUBTYPES = %w[Draw Win].freeze
  SUBTYPES = SELECTABLE_SUBTYPES + %w[Loss Penalty].freeze
  ELIMINATION_SELECTABLE_SUBYTPES = %w[Advance].freeze
  ELIMINATION_SUBYTPES = ELIMINATION_SELECTABLE_SUBYTPES + %w[Eliminated].freeze

  scope :publishable, -> { joins(:round).where.not(rounds: { finished_at: nil }) }

  validates(
    :tournament_participant_id,
    {
      uniqueness: { scope: :round_id }
    }
  )

  def self.create_or_update_by(**keys)
    result = Result.find_by(keys)
    result = Result.new(keys) if result.blank?

    yield(result)

    result.save
  end
end
