# frozen_string_literal: true

require "test_helper"

module Tournaments
  class FinishTournamentJobTest < ActiveJob::TestCase
    test "job runs without errors" do
      tournament = events(:small_tournament)

      # Since the job currently has no implementation, just verify it runs
      assert_nothing_raised do
        Tournaments::FinishTournamentJob.perform_now(tournament)
      end
    end

    test "job is queued with correct arguments" do
      tournament = events(:small_tournament)

      assert_enqueued_with(job: Tournaments::FinishTournamentJob, args: [tournament]) do
        Tournaments::FinishTournamentJob.perform_later(tournament)
      end
    end
  end
end
