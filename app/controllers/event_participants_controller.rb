# frozen_string_literal: true

class EventParticipantsController < ApplicationController
  skip_before_action :require_authentication, only: %i[index]

  def index
    @tournament = load_tournament
    render layout: "modal"
  end

  def new
    tournament = load_tournament
    @event_participant = EventParticipant.new(tournament: tournament, player: current_user.player)
  end

  def edit
    @tournament = load_tournament
    @event_participant = load_participant(@tournament)
  end

  def create
    tournament = load_tournament
    @event_participant = EventParticipant.new(tournament: tournament, player: current_user.player)
    @event_participant.attributes = event_participant_params

    if @event_participant.save
      redirect_to @event_participant.tournament, notice: "Registration successful!"
    else
      render :new, status: :unprocessable_entity, layout: "modal"
    end
  end

  def update
    @tournament = load_tournament
    @event_participant = load_participant(@tournament)
    @event_participant.update(event_participant_params)

    redirect_to @event_participant.tournament, notice: "Update successful!"
  end

  def destroy
    @tournament = load_tournament
    @destroyed_participant = load_participant(@tournament)

    # TODO: message for this
    return if !@tournament.registration_open? && !@tournament.registration_closed?

    @destroyed_participant.destroy
    @event_participant = EventParticipant.new

    redirect_to @tournament, notice: "Registration canceled!"
  end

  private

  def event_participant_params
    params.expect(event_participant: [
                    :accepted_terms,
                    :decklist
                  ])
  end

  def load_tournament
    Tournament.find params[:tournament_id]
  end

  def load_participant(tournament)
    tournament.event_participants.find_by(player: current_user.player)
  end
end
