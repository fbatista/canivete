# frozen_string_literal: true

require "test_helper"

module Tournaments
  class StartSingleEliminationRoundJobTest < ActiveJob::TestCase
    test "creates new single elimination round with incremented number" do
      event = Event.find_by(type: "Tournament", slug: "standard-tournament")
      initial_round_count = event.rounds.count

      # Perform the job
      Tournaments::StartSingleEliminationRoundJob.perform_now(event)

      # Verify new round was created
      assert_equal initial_round_count + 1, event.rounds.count

      new_round = event.rounds.where(type: "SingleEliminationRound").last
      assert_equal "SingleEliminationRound", new_round.type
      assert_equal initial_round_count + 1, new_round.number
    end

    test "job is queued with correct arguments" do
      event = Event.find_by(type: "Tournament", slug: "standard-tournament")

      assert_enqueued_with(job: Tournaments::StartSingleEliminationRoundJob, args: [event]) do
        Tournaments::StartSingleEliminationRoundJob.perform_later(event)
      end
    end
  end
end
