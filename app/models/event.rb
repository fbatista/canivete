# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :event_organizer
  has_many :rounds, dependent: :destroy
  has_many :event_participants, dependent: :destroy
  has_many :infractions, dependent: :destroy
  has_many :pods, through: :rounds

  PREFERRED_POD_SIZE = 4
  SMALLER_POD_SIZE = 3
  LARGER_POD_SIZE = 5

  scope :for_organizer, ->(organizer) { where(event_organizer: organizer) }
  scope :past, -> { where(end_time: ...Time.current) }
  scope :upcoming, -> { where(start_time: Time.current..) }
  scope :for_player, ->(player) { joins(:event_participants).where(event_participants: { player: player }) }

  enum :currency, EventOrganizer::CURRENCIES

  has_one_attached :cover

  with_options presence: true do
    validates :state, :name, :slug, :start_time, :end_time
  end

  before_validation :populate_slug

  after_update :perform_state_based_actions, if: -> { state_previously_changed? }
  after_save :geocode_address, if: -> { address_changed? }

  def available_states
    return self.class.states.slice(:draft) if new_record?

    self.class.states.slice(*(self.class::TRANSITIONS[state] - [state.to_sym]))
  end

  def geocode_address
    Events::GeocodeJob.perform_later(self)
  end

  def latitude=(latitude)
    self.location = RGeo::Geographic
      .spherical_factory(srid: 4326)
      .point(longitude, latitude)
  end

  def longitude=(longitude)
    self.location = RGeo::Geographic
      .spherical_factory(srid: 4326)
      .point(longitude, latitude)
  end

  def latitude
    location&.y || 0
  end

  def longitude
    location&.x || 0
  end

  def minimum_participants=(num_players)
    self.participants_range = (num_players.presence || 0).to_i..maximum_participants
  end

  def maximum_participants=(num_players)
    self.participants_range = minimum_participants..(num_players.presence&.to_i)
  end

  def minimum_participants
    participants_range&.begin || 0
  end

  def maximum_participants
    if participants_range&.end == Float::INFINITY || participants_range&.end.nil?
      Float::INFINITY
    else
      participants_range&.end
    end
  end

  def name_with_dates
    "#{name} (#{start_time.strftime('%d/%m/%Y')} - #{end_time.strftime('%d/%m/%Y')})"
  end
end
