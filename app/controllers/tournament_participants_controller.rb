# frozen_string_literal: true

class TournamentParticipantsController < ApplicationController
  skip_before_action :require_authentication, only: %i[index]

  def index
    @tournament = load_tournament
    render layout: "modal"
  end

  def new
    tournament = load_tournament
    @tournament_participant = TournamentParticipant.new(tournament:, player: current_user.player)
  end

  def create
    tournament = load_tournament
    @tournament_participant = TournamentParticipant.new(tournament:, player: current_user.player)
    @tournament_participant.attributes = tournament_participant_params

    if @tournament_participant.save
      redirect_to @tournament_participant.tournament, notice: "Registration successful!"
    else
      render :new, status: :unprocessable_entity, layout: "modal"
    end
  end

  def destroy
    @tournament = load_tournament
    @destroyed_participant = load_participant(@tournament)

    # TODO: message for this
    return if !@tournament.registration_open? && !@tournament.registration_closed?

    @destroyed_participant.destroy
    @tournament_participant = TournamentParticipant.new

    redirect_to @tournament, notice: "Registration canceled!"
  end

  def edit
    @tournament = load_tournament
    @tournament_participant = load_participant(@tournament)
  end

  def update
    @tournament = load_tournament
    @tournament_participant = load_participant(@tournament)
    @tournament_participant.update(tournament_participant_params)

    redirect_to @tournament_participant.tournament, notice: "Update successful!"
  end

  private

  def tournament_participant_params
    params.expect(tournament_participant: [
      :accepted_terms,
      :decklist
    ])
  end

  def load_tournament
    Tournament.find params[:tournament_id]
  end

  def load_participant(tournament)
    tournament.tournament_participants.find_by(player: current_user.player)
  end
end
