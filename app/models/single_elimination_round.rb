# frozen_string_literal: true

class SingleEliminationRound < Round
  def display_name
    event.single_elimination_round_name(number)
  end

  def create_pods
    Tournaments::CreateSingleEliminationPodsJob.perform_now(self)
  end

  def last_single_elimination_round?
    number == (
      event.number_of_swiss_rounds + event.number_of_single_elimination_rounds
    )
  end

  def duration
    last_single_elimination_round? ? nil : 150.minutes
  end

  def advance_tournament!
    return if last_single_elimination_round?

    Tournaments::StartSingleEliminationRoundJob.perform_now(event)
  end
end
