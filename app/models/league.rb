# frozen_string_literal: true

class League < ApplicationRecord
  has_many :tournaments, dependent: :nullify
  belongs_to :tournament_organizer

  def token(password)
    Digest::MD5.hexdigest("#{tournament_organizer_id}-#{password}")
  end

  def self.find_and_authenticate(id:, password:)
    find_by(id:, token: token(password))
  end
end
