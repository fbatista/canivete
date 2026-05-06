# frozen_string_literal: true

module Organizer
  class CircuitsController < OrganizerController
    def index
      @circuits = Circuit.for_organizer(current_organizer).preload(:tournaments)
        .page(params[:page])
    end

    def show
      @circuit = Circuit.for_organizer(current_organizer).preload(
        tournaments: :rounds,
        circuit_standings: :player
      ).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to [:organizer, :circuits], alert: t("flash.alert.not_authorized_circuit")
    end

    def new
      @circuit = Circuit.new
    end

    def edit
      @circuit = Circuit.for_organizer(current_organizer).find params[:id]
    end

    def create
      @circuit = Circuit.create!(
        circuit_params.merge(event_organizer: current_organizer)
      )

      redirect_to [:organizer, @circuit], notice: t("flash.notice.circuit_created")
    rescue ActiveRecord::RecordInvalid => e
      @circuit = Circuit.new(circuit_params.merge(event_organizer: current_organizer))
      @circuit.errors.add(:base, e.message)
      render :new, status: :unprocessable_entity
    end

    def update
      @circuit = Circuit.for_organizer(current_organizer).find(params[:id])
      @circuit.attributes = circuit_params

      if @circuit.save
        redirect_to [:organizer, @circuit], notice: t("flash.notice.circuit_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def circuit_params
      params.expect(circuit: %i[name description])
    end
  end
end
