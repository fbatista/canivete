# frozen_string_literal: true

class Room < ApplicationRecord
  belongs_to :event
end
