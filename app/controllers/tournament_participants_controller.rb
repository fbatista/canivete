# frozen_string_literal: true

class TournamentParticipantsController < ApplicationController
  def index
    @tournament = load_tournament
  end

  def me
    @tournament = load_tournament
    @tournament_participant = load_participant(@tournament)

    if @tournament_participant.present?
      render :show
    else
      @tournament_participant = TournamentParticipant.new
      render :new
    end
  end

  def create
    @tournament = load_tournament
    @tournament_participant = @tournament.tournament_participants.create(player: current_user.player)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to [:me, @tournament, :tournament_participant], notice: 'Registration successful!' }
    end
  end

  def destroy
    @tournament = load_tournament
    @destroyed_participant = load_participant(@tournament)
    @destroyed_participant.destroy

    @tournament_participant = TournamentParticipant.new

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to [:me, @tournament, :tournament_participant], notice: 'Registration canceled!' }
    end
  end

  private

  def load_tournament
    Tournament.find params[:tournament_id]
  end

  def load_participant(tournament)
    tournament.tournament_participants.find_by(player: current_user.player)
  end
end
