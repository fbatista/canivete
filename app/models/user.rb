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
  after_create :initialize_player
  after_update :update_key, if: -> { email_previously_changed? || name_previously_changed? }

  has_one :player

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  def compute_key
    Digest::MD5.hexdigest(email + name)
  end

  def initialize_player
    player = Player.find_or_initialize_by(key: compute_key)
    player.user = self
    player.save
  end

  def update_key
    player.update(key: compute_key)
  end
end
