# frozen_string_literal: true

require "test_helper"

class Tournaments::FinishRoundJobTest < ActiveJob::TestCase
  test "job runs without errors" do
    round = rounds(:small_tournament_round_1)
    
    # Since the job currently has no implementation, just verify it runs
    assert_nothing_raised do
      Tournaments::FinishRoundJob.perform_now(round)
    end
  end
  
  test "job is queued with correct arguments" do
    round = rounds(:small_tournament_round_1)
    
    assert_enqueued_with(job: Tournaments::FinishRoundJob, args: [round]) do
      Tournaments::FinishRoundJob.perform_later(round)
    end
  end
end