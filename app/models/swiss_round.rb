# frozen_string_literal: true

class SwissRound < Round
  validates(
    :number,
    {
      presence: true,
      uniqueness: { scope: :tournament_id },
      numericality: true,
      inclusion: { in: 1.. }
    }
  )

  def create_pods
    Tournaments::CreatePodsJob.perform_now(self)
  end

  def last_swiss_round?
    number == tournament.number_of_swiss_rounds
  end

  def advance_tournament!
    return if last_swiss_round?

    Tournaments::StartSwissRoundJob.perform_now(tournament)
  end
end
