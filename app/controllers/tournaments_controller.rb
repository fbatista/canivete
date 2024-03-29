# frozen_string_literal: true

class TournamentsController < ApplicationController
  def index
    @tournaments = Tournament.all
  end

  def new
    @tournament = Tournament.new
  end

  def create
    @tournament = Tournament.create(tournament_params)

    redirect_to @tournament, notice: 'Tournament create successfully'
  end

  def show
    @tournament = Tournament.preload(rounds: :pods, tournament_participants: { player: :user }).find(params[:id])
  end

  def edit
    @tournament = Tournament.find params[:id]
  end

  def update
    @tournament = Tournament.find params[:id]
    @tournament.attributes = tournament_params

    if @tournament.save
      redirect_to @tournament, notice: 'Tournament updated successfully'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def tournament_params
    params.require(:tournament).permit(
      :name,
      :state
    )
  end
end
