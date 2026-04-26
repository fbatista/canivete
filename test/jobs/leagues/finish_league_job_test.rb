# frozen_string_literal: true

require "test_helper"

module Leagues
  class FinishLeagueJobTest < ActiveJob::TestCase
    setup do
      @league = leagues(:standard_league)
    end

    test "enqueues finish league" do
      assert_enqueued_with(job: Leagues::FinishLeagueJob, args: [@league]) do
        Leagues::FinishLeagueJob.perform_later(@league)
      end
    end

    test "triggers circuit standings update when league has circuit" do
      @league.update!(circuit: circuits(:standard_circuit))
      @league.event_participants.each_with_index do |ep, i|
        ep.update!(final_position: i + 1)
      end

      # perform_now executes synchronously — verify standings were updated
      Leagues::FinishLeagueJob.perform_now(@league)

      standing = circuits(:standard_circuit).circuit_standings.find_by(player: @league.event_participants.first.player)
      assert_not_nil standing
      assert_equal 4.0, standing.points  # 4 participants, position 1 = 4 points
    end

    test "does not trigger circuit update when league has no circuit" do
      @league.update!(circuit: nil)
      @league.event_participants.each_with_index do |ep, i|
        ep.update!(final_position: i + 1)
      end

      # Should not raise — no circuit to update
      assert_nothing_raised do
        Leagues::FinishLeagueJob.perform_now(@league)
      end
    end
  end
end
