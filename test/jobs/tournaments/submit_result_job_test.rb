# frozen_string_literal: true

require "test_helper"

class Tournaments::SubmitResultJobTest < ActiveJob::TestCase
  test "handles Win result correctly" do
    pod = pods(:small_tournament_pod_1)
    round = pod.round
    winner = tournament_participants(:small_tournament_participant_one)
    
    # Clear any existing results for clean test
    Result.where(round: round).destroy_all
    
    # Perform the job
    Tournaments::SubmitResultJob.perform_now(
      type: "Win",
      tournament_participant: winner,
      round: round,
      pod: pod
    )
    
    # Verify winner got Win result
    winner_result = Result.find_by(tournament_participant: winner, round: round)
    assert_not_nil winner_result
    assert_instance_of Win, winner_result
    
    # Verify other participants got Loss results
    other_participants = pod.tournament_participants.reject { |tp| tp == winner }
    other_participants.each do |participant|
      result = Result.find_by(tournament_participant: participant, round: round)
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
    Tournaments::SubmitResultJob.perform_now(
      type: "Draw",
      tournament_participant: pod.tournament_participants.first,
      round: round,
      pod: pod
    )
    
    # Verify all participants got Draw results
    pod.tournament_participants.each do |participant|
      result = Result.find_by(tournament_participant: participant, round: round)
      assert_not_nil result
      assert_instance_of Draw, result
    end
  end
  
  test "handles Penalty result correctly" do
    pod = pods(:small_tournament_pod_1)
    round = pod.round
    penalized_participant = tournament_participants(:small_tournament_participant_one)
    
    # Clear any existing results for clean test
    Result.where(round: round).destroy_all
    
    # Perform the job
    Tournaments::SubmitResultJob.perform_now(
      type: "Penalty",
      tournament_participant: penalized_participant,
      round: round,
      pod: pod
    )
    
    # Verify penalized participant got Penalty result
    penalty_result = Result.find_by(tournament_participant: penalized_participant, round: round)
    assert_not_nil penalty_result
    assert_instance_of Penalty, penalty_result
  end
  
  test "handles Advance result correctly" do
    pod = pods(:medium_tournament_pod_1)
    round = pod.round
    advancing_participant = tournament_participants(:medium_tournament_participant_one)
    
    # Clear any existing results for clean test
    Result.where(round: round).destroy_all
    
    # Perform the job
    Tournaments::SubmitResultJob.perform_now(
      type: "Advance",
      tournament_participant: advancing_participant,
      round: round,
      pod: pod
    )
    
    # Verify advancing participant got Advance result
    advance_result = Result.find_by(tournament_participant: advancing_participant, round: round)
    assert_not_nil advance_result
    assert_instance_of Advance, advance_result
    
    # Verify other participants got Eliminated results
    other_participants = pod.tournament_participants.reject { |tp| tp == advancing_participant }
    other_participants.each do |participant|
      result = Result.find_by(tournament_participant: participant, round: round)
      assert_not_nil result
      assert_instance_of Eliminated, result
    end
  end
  
  test "preserves existing Penalty results when handling Win" do
    pod = pods(:small_tournament_pod_1)
    round = pod.round
    winner = tournament_participants(:small_tournament_participant_one)
    penalized_participant = tournament_participants(:small_tournament_participant_two)
    
    # Clear existing results and create a penalty
    Result.where(round: round).destroy_all
    Penalty.create!(tournament_participant: penalized_participant, round: round)
    
    # Submit a win
    Tournaments::SubmitResultJob.perform_now(
      type: "Win",
      tournament_participant: winner,
      round: round,
      pod: pod
    )
    
    # Verify winner got Win result
    winner_result = Result.find_by(tournament_participant: winner, round: round)
    assert_instance_of Win, winner_result
    
    # Verify penalized participant kept Penalty result
    penalty_result = Result.find_by(tournament_participant: penalized_participant, round: round)
    assert_instance_of Penalty, penalty_result
  end
  
  test "preserves existing Penalty results when handling Draw" do
    pod = pods(:small_tournament_pod_1)
    round = pod.round
    penalized_participant = tournament_participants(:small_tournament_participant_one)
    
    # Clear existing results and create a penalty
    Result.where(round: round).destroy_all
    Penalty.create!(tournament_participant: penalized_participant, round: round)
    
    # Submit a draw
    Tournaments::SubmitResultJob.perform_now(
      type: "Draw",
      tournament_participant: pod.tournament_participants.first,
      round: round,
      pod: pod
    )
    
    # Verify penalized participant kept Penalty result
    penalty_result = Result.find_by(tournament_participant: penalized_participant, round: round)
    assert_instance_of Penalty, penalty_result
    
    # Verify other participants got Draw results
    other_participants = pod.tournament_participants.reject { |tp| tp == penalized_participant }
    other_participants.each do |participant|
      result = Result.find_by(tournament_participant: participant, round: round)
      assert_instance_of Draw, result
    end
  end
  
  test "raises error when no winner provided for Win result" do
    pod = pods(:small_tournament_pod_1)
    round = pod.round
    
    # Should raise error with nil tournament_participant
    assert_raises(RuntimeError, "Must select a winner") do
      Tournaments::SubmitResultJob.perform_now(
        type: "Win",
        tournament_participant: nil,
        round: round,
        pod: pod
      )
    end
  end
  
  test "job is queued with correct arguments" do
    pod = pods(:small_tournament_pod_1)
    round = pod.round
    participant = tournament_participants(:small_tournament_participant_one)
    
    expected_args = {
      type: "Win",
      tournament_participant: participant,
      round: round,
      pod: pod
    }
    
    assert_enqueued_with(job: Tournaments::SubmitResultJob, args: [expected_args]) do
      Tournaments::SubmitResultJob.perform_later(**expected_args)
    end
  end
end