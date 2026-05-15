# frozen_string_literal: true

module Organizer
  class EventParticipantsController < OrganizerController
    layout "modal"

    def index
      @event = load_tournament

      case @event.state
      when "registration_open", "registration_closed"
        @event_participants = @event.event_participants.includes(player: :user).joins(player: :user).order(:name)
      else
        @event_participants =
          @event.event_participants.sort_by do |p|
            [
              p.playing? ? 0 : 1,
              -p.rank_score,
              -p.times_going_at(4),
              -p.times_going_at(3),
              -p.times_going_at(2),
              -p.times_going_at(1),
              p.name
            ]
          end
        @event_participants.each.with_index do |p, i|
          p.rank = i + 1
        end
      end

      if params[:query].present?
        @event_participants =
          @event_participants.select do |p|
            p.name.downcase.include?(params[:query].downcase)
          end
      end

      @layout_mode = "modal"
      return unless params[:layout] == "application"

      @layout_mode = "application"
      render layout: "application"
    end

    def new
      @event_participant = EventParticipant.new(event: load_tournament)
    end

    def create
      @event_participant = EventParticipant.new(event: load_tournament)
      @event_participant.attributes = event_participant_params

      if @event_participant.save
        redirect_to [:organizer, @event_participant.event, :event_participants, { layout: "application" }],
                    notice: "#{@event_participant.name} added!"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @event = load_tournament
      @event_participant = load_event_participant(@event)

      @event_participant.update(event_participant_params)
      # TODO: stay in place or fix the updated item
      redirect_to [:organizer, @event, :event_participants, { layout: "application" }],
                  notice: "#{@event_participant.name} #{@event_participant.dropped? ? 'dropped' : 'updated'}!"
    end

    def destroy; end

    private

    def load_tournament
      Tournament.for_organizer(current_organizer).find params[:tournament_id]
    end

    def load_event_participant(tournament)
      tournament.event_participants.find(params[:id])
    end

    def event_participant_params
      params.expect(event_participant: %i[
                      dropped
                      checked_in
                      paid
                      player_email
                      player_name
                      decklist
                      accepted_terms
                    ])
    end
  end
end
