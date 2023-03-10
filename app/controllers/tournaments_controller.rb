class TournamentsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @tournaments = Tournament.all
  end
end
