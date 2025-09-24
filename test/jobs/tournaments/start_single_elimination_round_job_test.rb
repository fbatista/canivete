# frozen_string_literal: true

require "test_helper"

class Tournaments::StartSingleEliminationRoundJobTest < ActiveJob::TestCase
  test "creates new single elimination round with incremented number" do
    tournament = tournaments(:standard_tournament)
    initial_round_count = tournament.rounds.count
    # TODO add swiss rounds
    flunk "Need to add swiss rounds to standard_tournament fixture"

    # Perform the job
    Tournaments::StartSingleEliminationRoundJob.perform_now(tournament)

    # Verify new round was created
    assert_equal initial_round_count + 1, tournament.rounds.count

    new_round = tournament.rounds.last
    assert_equal "SingleEliminationRound", new_round.type
    assert_equal initial_round_count + 1, new_round.number
  end

  test "job is queued with correct arguments" do
    tournament = tournaments(:standard_tournament)

    assert_enqueued_with(job: Tournaments::StartSingleEliminationRoundJob, args: [ tournament ]) do
      Tournaments::StartSingleEliminationRoundJob.perform_later(tournament)
    end
  end
end
