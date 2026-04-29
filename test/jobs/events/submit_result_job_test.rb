# frozen_string_literal: true

require "test_helper"

module Events
  class SubmitResultJobTest < ActiveJob::TestCase # rubocop:disable Metrics/ClassLength
    test "handles Win result correctly" do
      pod = pods(:small_tournament_pod_1)
      round = pod.round
      winner = event_participants(:small_event_participant_one)

      # Clear any existing results for clean test
      Result.where(round: round).destroy_all

      # Perform the job
      Events::SubmitResultJob.perform_now(
        type: "Win",
        event_participant: winner,
        round: round,
        pod: pod
      )

      # Verify winner got Win result
      winner_result = Result.find_by(event_participant: winner, round: round)
      assert_not_nil winner_result
      assert_instance_of Win, winner_result

      # Verify other participants got Loss results
      other_participants = pod.event_participants.reject { |tp| tp == winner }
      other_participants.each do |participant|
        result = Result.find_by(event_participant: participant, round: round)
        assert_not_nil result
        assert_instance_of Loss, result
      end
    end

    test "handles Draw result correctly" do
      pod = pods(:small_tournament_pod_1)
      round = pod.round

      # Clear any existing results for clean test
      Result.where(round: round).destroy_all

      # Perform the job (participant doesn't matter for draws)
      Events::SubmitResultJob.perform_now(
        type: "Draw",
        event_participant: pod.event_participants.first,
        round: round,
        pod: pod
      )

      # Verify all participants got Draw results
      pod.event_participants.each do |participant|
        result = Result.find_by(event_participant: participant, round: round)
        assert_not_nil result
        assert_instance_of Draw, result
      end
    end

    test "handles Penalty result correctly" do
      pod = pods(:small_tournament_pod_1)
      round = pod.round
      penalized_participant = event_participants(:small_event_participant_one)

      # Clear any existing results for clean test
      Result.where(round: round).destroy_all

      # Perform the job
      Events::SubmitResultJob.perform_now(
        type: "Penalty",
        event_participant: penalized_participant,
        round: round,
        pod: pod
      )

      # Verify penalized participant got Penalty result
      penalty_result = Result.find_by(event_participant: penalized_participant, round: round)
      assert_not_nil penalty_result
      assert_instance_of Penalty, penalty_result
    end

    test "handles Advance result correctly" do
      pod = pods(:medium_tournament_pod_1)
      round = pod.round
      advancing_participant = event_participants(:medium_event_participant_one)

      # Clear any existing results for clean test
      Result.where(round: round).destroy_all

      # Perform the job
      Events::SubmitResultJob.perform_now(
        type: "Advance",
        event_participant: advancing_participant,
        round: round,
        pod: pod
      )

      # Verify advancing participant got Advance result
      advance_result = Result.find_by(event_participant: advancing_participant, round: round)
      assert_not_nil advance_result
      assert_instance_of Advance, advance_result

      # Verify other participants got Eliminated results
      other_participants = pod.event_participants.reject { |tp| tp == advancing_participant }
      other_participants.each do |participant|
        result = Result.find_by(event_participant: participant, round: round)
        assert_not_nil result
        assert_instance_of Eliminated, result
      end
    end

    test "preserves existing Penalty results when handling Win" do
      pod = pods(:small_tournament_pod_1)
      round = pod.round
      winner = event_participants(:small_event_participant_one)
      penalized_participant = event_participants(:small_event_participant_two)

      # Clear existing results and create a penalty
      Result.where(round: round).destroy_all
      Penalty.create!(event_participant: penalized_participant, round: round)

      # Submit a win
      Events::SubmitResultJob.perform_now(
        type: "Win",
        event_participant: winner,
        round: round,
        pod: pod
      )

      # Verify winner got Win result
      winner_result = Result.find_by(event_participant: winner, round: round)
      assert_instance_of Win, winner_result

      # Verify penalized participant kept Penalty result
      penalty_result = Result.find_by(event_participant: penalized_participant, round: round)
      assert_instance_of Penalty, penalty_result
    end

    test "preserves existing Penalty results when handling Draw" do
      pod = pods(:small_tournament_pod_1)
      round = pod.round
      penalized_participant = event_participants(:small_event_participant_one)

      # Clear existing results and create a penalty
      Result.where(round: round).destroy_all
      Penalty.create!(event_participant: penalized_participant, round: round)

      # Submit a draw
      Events::SubmitResultJob.perform_now(
        type: "Draw",
        event_participant: pod.event_participants.first,
        round: round,
        pod: pod
      )

      # Verify penalized participant kept Penalty result
      penalty_result = Result.find_by(event_participant: penalized_participant, round: round)
      assert_instance_of Penalty, penalty_result

      # Verify other participants got Draw results
      other_participants = pod.event_participants.reject { |tp| tp == penalized_participant }
      other_participants.each do |participant|
        result = Result.find_by(event_participant: participant, round: round)
        assert_instance_of Draw, result
      end
    end

    test "raises error when no winner provided for Win result" do
      pod = pods(:small_tournament_pod_1)
      round = pod.round

      # Should raise error with nil event_participant
      assert_raises(RuntimeError, "Must select a winner") do
        Events::SubmitResultJob.perform_now(
          type: "Win",
          event_participant: nil,
          round: round,
          pod: pod
        )
      end
    end

    test "job is queued with correct arguments" do
      pod = pods(:small_tournament_pod_1)
      round = pod.round
      participant = event_participants(:small_event_participant_one)

      expected_args = {
        type: "Win",
        event_participant: participant,
        round: round,
        pod: pod
      }

      assert_enqueued_with(job: Events::SubmitResultJob, args: [expected_args]) do
        Events::SubmitResultJob.perform_later(**expected_args)
      end
    end
  end
end
