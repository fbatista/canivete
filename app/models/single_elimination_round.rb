# frozen_string_literal: true

class SingleEliminationRound < Round
  def create_pods
    Tournaments::CreatePodsJob.perform_now(self)
  end
end
