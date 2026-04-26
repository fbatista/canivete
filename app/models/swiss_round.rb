# frozen_string_literal: true

class SwissRound < Round
  validates(
    :number,
    {
      presence: true,
      uniqueness: { scope: :event_id, message: "must be unique per event" },
      numericality: true,
      inclusion: { in: 1.. }
    }
  )

  def display_name
    "Round ##{number}"
  end

  def duration
    80.minutes
  end

  def create_pods
    Tournaments::CreatePodsJob.perform_now(self)
  end

  def last_swiss_round?
    number == event.number_of_swiss_rounds
  end

  def advance_tournament!
    return if last_swiss_round?

    Tournaments::StartSwissRoundJob.perform_now(event)
  end
end
