# frozen_string_literal: true

require "test_helper"

module Leagues
  class StartFinalsRoundJobTest < ActiveJob::TestCase
    setup do
      @league = leagues(:standard_league)
    end

    test "enqueues start finals round" do
      assert_enqueued_with(job: Leagues::StartFinalsRoundJob, args: [@league]) do
        Leagues::StartFinalsRoundJob.perform_later(@league)
      end
    end

    test "creates a single elimination finals round" do
      Leagues::StartFinalsRoundJob.perform_now(@league)

      round = @league.rounds.last
      assert round.is_finals_round
      assert_not round.is_play_round
      assert_equal "SingleEliminationRound", round.type
      assert round.is_a?(SingleEliminationRound)
    end
  end
end
