# frozen_string_literal: true

class EventParticipantsController < ApplicationController
  skip_before_action :require_authentication, only: %i[index]

  def index
    @event = load_event
    render layout: "modal"
  end

  def new
    event = load_event
    @event_participant = EventParticipant.new(event: event, player: current_user.player)
  end

  def edit
    @event = load_event
    @event_participant = load_participant(@event)
  end

  def create
    event = load_event
    @event_participant = EventParticipant.new(event: event, player: current_user.player)
    @event_participant.attributes = event_participant_params

    if @event_participant.save
      redirect_to @event_participant.event, notice: "Registration successful!"
    else
      render :new, status: :unprocessable_entity, layout: "modal"
    end
  end

  def update
    @event = load_event
    @event_participant = load_participant(@event)
    @event_participant.update(event_participant_params)

    redirect_to @event_participant.event, notice: "Update successful!"
  end

  def destroy
    @event = load_event
    @destroyed_participant = load_participant(@event)

    # TODO: message for this
    return if !@event.registration_open? && !@event.registration_closed?

    @destroyed_participant.destroy
    @event_participant = EventParticipant.new

    redirect_to @event, notice: "Registration canceled!"
  end

  private

  def event_participant_params
    params.expect(event_participant: [
                    :accepted_terms,
                    :decklist
                  ])
  end

  def load_event
    Tournament.find params[:tournament_id]
  end

  def load_participant(event)
    event.event_participants.find_by(player: current_user.player)
  end
end
