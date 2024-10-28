# frozen_string_literal: true

class SingleEliminationRound < Round
  def display_name
    tournament.single_elimination_round_name(number)
  end

  def create_pods
    Tournaments::CreateSingleEliminationPodsJob.perform_now(self)
  end

  def last_single_elimination_round?
    number == (
      tournament.number_of_swiss_rounds + tournament.number_of_single_elimination_rounds
    )
  end

  def advance_tournament!
    return if last_single_elimination_round?

    Tournaments::StartSingleEliminationRoundJob.perform_now(tournament)
  end
end
