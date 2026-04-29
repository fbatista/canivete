# frozen_string_literal: true

require "test_helper"

module Leagues
  class StartPlayRoundJobTest < ActiveJob::TestCase
    setup do
      @league = leagues(:standard_league)
    end

    test "enqueues start play round" do
      assert_enqueued_with(job: Leagues::StartPlayRoundJob, args: [@league]) do
        Leagues::StartPlayRoundJob.perform_later(@league)
      end
    end

    test "creates a new Swiss play round" do
      assert_difference -> { @league.rounds.count }, 1 do
        Leagues::StartPlayRoundJob.perform_now(@league)
      end

      round = @league.rounds.last
      assert round.is_play_round
      assert_not round.is_finals_round
      assert_equal "SwissRound", round.type
      assert round.is_a?(SwissRound)
    end

    test "sets correct round number" do
      Leagues::StartPlayRoundJob.perform_now(@league)
      first = @league.rounds.last

      Leagues::StartPlayRoundJob.perform_now(@league)
      second = @league.rounds.last

      assert_equal 1, first.number
      assert_equal 2, second.number
    end
  end
end
