# frozen_string_literal: true

require "test_helper"

class Tournaments::StartSwissRoundJobTest < ActiveJob::TestCase
  test "creates new swiss round with incremented number" do
    # Use large_tournament which doesn't have fixture rounds
    tournament = tournaments(:large_tournament)
    initial_round_count = tournament.rounds.count
    
    # Perform the job
    Tournaments::StartSwissRoundJob.perform_now(tournament)
    
    # Verify new round was created
    tournament.reload
    assert_equal initial_round_count + 1, tournament.rounds.count
    
    new_round = tournament.rounds.order(:number).last
    assert_equal "SwissRound", new_round.type
    # The new round number should be initial_round_count + 1
    assert_equal initial_round_count + 1, new_round.number
  end
  
  test "job is queued with correct arguments" do
    tournament = tournaments(:small_tournament)
    
    assert_enqueued_with(job: Tournaments::StartSwissRoundJob, args: [tournament]) do
      Tournaments::StartSwissRoundJob.perform_later(tournament)
    end
  end
end