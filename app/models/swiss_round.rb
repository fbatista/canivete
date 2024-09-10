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

  def past?
    tournament.rounds_count > number
  end

  def last_swiss_round?
    number == tournament.rounds_info[:rounds].size
  end
end
