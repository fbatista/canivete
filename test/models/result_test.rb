# frozen_string_literal: true

require "test_helper"

class ResultTest < ActiveSupport::TestCase
  # ===== BASIC FIXTURE TEST =====
  
  test "fixtures load correctly" do
    assert_not_nil results(:win_result)
    assert_not_nil results(:loss_result)
    assert_not_nil results(:draw_result)
    assert_not_nil results(:penalty_result)
    assert_not_nil results(:advance_result)
    assert_not_nil results(:eliminated_result)
    
    # Verify STI types are correct
    assert_instance_of Win, results(:win_result)
    assert_instance_of Loss, results(:loss_result)
    assert_instance_of Draw, results(:draw_result)
    assert_instance_of Penalty, results(:penalty_result)
    assert_instance_of Advance, results(:advance_result)
    assert_instance_of Eliminated, results(:eliminated_result)
  end
  
  # ===== ASSOCIATIONS AND VALIDATIONS =====
  
  test "belongs to tournament_participant and round" do
    result = results(:win_result)
    assert_not_nil result.tournament_participant
    assert_not_nil result.round
    assert_not_nil result.tournament  # through round association
  end
  
  test "validates uniqueness of tournament_participant per round" do
    existing_result = results(:win_result)
    
    # Try to create another result for same participant in same round
    duplicate_result = Result.new(
      tournament_participant: existing_result.tournament_participant,
      round: existing_result.round,
      type: "Loss"
    )
    
    assert_not duplicate_result.valid?
    assert_includes duplicate_result.errors[:tournament_participant_id], "has already been taken"
  end
  
  # ===== STI HIERARCHY TESTS =====
  
  test "Win is a Result" do
    win = results(:win_result)
    assert_instance_of Win, win
    assert_kind_of Result, win
    assert_equal "Win", win.type
  end
  
  test "Loss is a Result" do
    loss = results(:loss_result)
    assert_instance_of Loss, loss
    assert_kind_of Result, loss
    assert_equal "Loss", loss.type
  end
  
  test "Draw is a Result" do
    draw = results(:draw_result)
    assert_instance_of Draw, draw
    assert_kind_of Result, draw
    assert_equal "Draw", draw.type
  end
  
  test "Penalty inherits from Loss" do
    penalty = results(:penalty_result)
    assert_instance_of Penalty, penalty
    assert_kind_of Loss, penalty  # Penalty < Loss < Result
    assert_kind_of Result, penalty
    assert_equal "Penalty", penalty.type
  end
  
  test "Advance is a Result" do
    advance = results(:advance_result)
    assert_instance_of Advance, advance
    assert_kind_of Result, advance
    assert_equal "Advance", advance.type
  end
  
  test "Eliminated is a Result" do
    eliminated = results(:eliminated_result)
    assert_instance_of Eliminated, eliminated
    assert_kind_of Result, eliminated
    assert_equal "Eliminated", eliminated.type
  end
  
  # ===== CONSTANTS TESTS =====
  
  test "SELECTABLE_SUBTYPES includes Draw and Win" do
    assert_includes Result::SELECTABLE_SUBTYPES, "Draw"
    assert_includes Result::SELECTABLE_SUBTYPES, "Win"
    assert_not_includes Result::SELECTABLE_SUBTYPES, "Loss"  # Loss is automatically created
    assert_not_includes Result::SELECTABLE_SUBTYPES, "Penalty"
  end
  
  test "SUBTYPES includes all swiss round result types" do
    assert_includes Result::SUBTYPES, "Draw"
    assert_includes Result::SUBTYPES, "Win"
    assert_includes Result::SUBTYPES, "Loss"
    assert_includes Result::SUBTYPES, "Penalty"
  end
  
  test "ELIMINATION constants include single elimination types" do
    assert_includes Result::ELIMINATION_SELECTABLE_SUBYTPES, "Advance"
    assert_includes Result::ELIMINATION_SUBYTPES, "Advance"
    assert_includes Result::ELIMINATION_SUBYTPES, "Eliminated"
  end
  
  # ===== SCOPE TESTS =====
  
  test "publishable scope returns only results from finished rounds" do
    # Results from finished rounds should be included
    publishable_results = Result.publishable
    assert_includes publishable_results, results(:win_result)  # from finished round
    assert_includes publishable_results, results(:loss_result)  # from finished round
    
    # Create result from unfinished round to test exclusion
    unfinished_result = Result.create!(
      tournament_participant: tournament_participants(:small_tournament_participant_one),
      round: rounds(:ongoing_round),  # unfinished round
      type: "Win"
    )
    
    assert_not_includes publishable_results, unfinished_result
  end
  
  # ===== CLASS METHOD TESTS =====
  
  test "create_or_update_by finds existing result" do
    existing_result = results(:win_result)
    original_id = existing_result.id
    
    # Should find and update the existing result (but keep same type for STI)
    found_result = nil
    Result.create_or_update_by(
      tournament_participant: existing_result.tournament_participant,
      round: existing_result.round
    ) do |result|
      found_result = result
      # Don't change type due to STI complications - just verify it was found
    end
    
    assert_equal original_id, found_result.id
    assert_instance_of Win, found_result
  end
  
  test "create_or_update_by creates new result when not found" do
    # Use a different participant/round combination
    participant = tournament_participants(:small_tournament_participant_one)
    round = rounds(:ongoing_round)
    
    # Should create a new result
    new_result = nil
    Result.create_or_update_by(
      tournament_participant: participant,
      round: round
    ) do |result|
      new_result = result
      result.type = "Draw"
    end
    
    assert new_result.persisted?
    assert_equal "Draw", new_result.type
    assert_equal participant, new_result.tournament_participant
    assert_equal round, new_result.round
  end
end