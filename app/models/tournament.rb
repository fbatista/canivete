class Tournament < ApplicationRecord
  has_many :rounds, dependent: :destroy

  POD_SIZE = 4
  POINTS_PER_WIN = 5
  POINTS_PER_BYE = 5
  POINTS_PER_LOSS = 0
  POINTS_PER_DRAW = 1

  enum :state, [:registration, :swiss, :single_elimination, :finished], default: :registration

  validates :name, presence: true
  validates :slug, presence: true

  before_validation :populate_slug
  
  def populate_slug
    self.slug = self.name.downcase.gsub(/[^a-z0-9]/, "-")
  end

end
