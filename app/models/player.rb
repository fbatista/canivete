# frozen_string_literal: true

class Player < ApplicationRecord
  belongs_to :user, optional: true

  has_many :event_participations, class_name: "EventParticipant", dependent: :destroy
  has_many :events, through: :event_participations
  has_many :infractions, dependent: :destroy

  validates :key, presence: true
  delegate :name, to: :user

  def participant?(event)
    event_participations.any? { |ep| ep.event_id == event.id }
  end

  def participant(event)
    event_participations.find { |ep| ep.event_id == event.id }
  end
end
