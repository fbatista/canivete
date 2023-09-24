# frozen_string_literal: true

class Result < ApplicationRecord
  belongs_to :tournament_participant
  belongs_to :round

  has_one :tournament, through: :round
end
