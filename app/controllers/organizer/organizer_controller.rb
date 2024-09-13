# frozen_string_literal: true

module Organizer
  class OrganizerController < ApplicationController
    before_action :authorize_user!

    def authorize_user!
      redirect_to root_url, alert: 'Not allowed' unless current_user.organizer?
    end

    def current_organizer
      current_user.tournament_organizer
    end
  end
end
