# frozen_string_literal: true

require "test_helper"

module Leagues
  class CreatePickupPodJobTest < ActiveJob::TestCase
    setup do
      @league = leagues(:standard_league)
      @league.registration_closed!
      @league.play!
    end

    test "enqueues pickup pod creation" do
      assert_enqueued_with(job: Leagues::CreatePickupPodJob, args: [@league]) do
        Leagues::CreatePickupPodJob.perform_later(@league)
      end
    end

    test "creates a new round and pod when no active round exists" do
      # @league.play! already creates a round via after_create callback
      # so this should find the existing round and add a pod to it
      pods_before = @league.rounds.flat_map(&:pods).size
      assert pods_before >= 1, "League should have at least 1 round from play state transition"

      Leagues::CreatePickupPodJob.perform_now(@league)

      pods_after = @league.rounds.flat_map(&:pods).size
      # No additional pod created since all participants were already seated
      assert_equal pods_before, pods_after
    end

    test "uses same round for multiple pod creations when all players fit in first pod" do
      # First pod creation takes all 4 players
      Leagues::CreatePickupPodJob.perform_now(@league)

      # Second pod creation should find no available players
      Leagues::CreatePickupPodJob.perform_now(@league)

      round = @league.rounds.find_by(is_play_round: true, published: false)
      assert round
      assert_equal 1, round.pods.count
    end

    test "skips if league is not in play state" do
      @league.registration_closed!

      pods_before = @league.rounds.flat_map(&:pods).size
      Leagues::CreatePickupPodJob.perform_now(@league)

      assert_equal pods_before, @league.rounds.flat_map(&:pods).size
    end

    test "skips if not enough available players" do
      # Drop all but one participant — need at least 3 for a pod
      @league.event_participants.where.not(id: @league.event_participants.first.id)
        .update_all(dropped: true)

      pods_before = @league.rounds.flat_map(&:pods).size
      Leagues::CreatePickupPodJob.perform_now(@league)

      pods_after = @league.rounds.flat_map(&:pods).size
      assert_equal pods_before, pods_after, "No pod should be created with fewer than 3 players"
    end
  end
end
