# frozen_string_literal: true

class User < ApplicationRecord
  attribute :organizer, :boolean, default: false

  has_secure_password
  has_many :sessions, dependent: :destroy

  after_create :initialize_player, if: -> { !organizer }
  after_create :initialize_organizer, if: -> { organizer }
  after_update :update_key, if: -> { email_address_previously_changed? || name_previously_changed? }

  has_one :player, dependent: :nullify
  has_one :tournament_organizer, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true

  def compute_key
    Digest::MD5.hexdigest(email_address + name)
  end

  def initialize_player
    self.player = Player.find_or_initialize_by(key: compute_key)
    player.save
  end

  def initialize_organizer
    TournamentOrganizer.create!(user: self)
  end

  def update_key
    player.update(key: compute_key)
  end

  def organizer?(tournament = nil)
    tournament_organizer.present? && (tournament.blank? || tournament_organizer.tournaments.include?(tournament))
  end

  def player?(tournament = nil)
    player.present? && (tournament.blank? || player.tournaments.include?(tournament))
  end
end
