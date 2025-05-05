# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication

  layout "modal", only: %i[new edit]
end
