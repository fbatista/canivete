# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise(
    :database_authenticatable,
    :registerable,
    :recoverable,
    :rememberable,
    :validatable
  )

  attribute :organizer, :boolean, default: false

  after_create :initialize_player, if: -> { !organizer? }
  after_create :initialize_organizer, if: -> { organizer? }
  after_update :update_key, if: -> { email_previously_changed? || name_previously_changed? }

  has_one :player, dependent: :nullify
  has_one :tournament_organizer, dependent: :nullify

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  def compute_key
    Digest::MD5.hexdigest(email + name)
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
