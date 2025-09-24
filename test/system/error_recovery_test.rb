# frozen_string_literal: true

require "application_system_test_case"

class ErrorRecoveryTest < ApplicationSystemTestCase
  test "handles tournament state transition errors gracefully" do
    organizer = users(:organizer_user)
    tournament = tournaments(:small_tournament)
    sign_in_as(organizer)
    
    # Try to start Swiss rounds without closing registration first
    visit organizer_tournament_path(tournament)
    
    assert_no_link "Start Swiss Rounds"
    assert_text "Draft"
    
    # Open registration first
    click_link "Open Registration"
    assert_text "Registration opened successfully"
    
    # Try to start Swiss with no participants
    click_link "Close Registration"
    click_link "Start Swiss Rounds"
    
    # Should show error or prevent action
    assert_current_path organizer_tournament_path(tournament)
  end
  
  test "handles invalid form submissions gracefully" do
    organizer = users(:organizer_user)
    sign_in_as(organizer)
    
    visit organizer_tournaments_path
    click_link "New Tournament"
    
    # Submit form with missing required fields
    fill_in "Name", with: ""
    click_button "Create Tournament"
    
    assert_text "Name can't be blank"
    assert_current_path organizer_tournaments_path
    
    # Submit with invalid max_participants
    fill_in "Name", with: "Test Tournament"
    fill_in "Max participants", with: "0"
    click_button "Create Tournament"
    
    assert_text "Max participants must be greater than 0"
  end
  
  test "handles unauthorized access attempts" do
    player = users(:player_one)
    tournament = tournaments(:small_tournament)
    sign_in_as(player)
    
    # Try to access organizer area
    visit organizer_tournament_path(tournament)
    
    assert_current_path root_path
    assert_text "You are not authorized to access this page"
  end
  
  test "handles non-existent resource requests" do
    organizer = users(:organizer_user)
    sign_in_as(organizer)
    
    # Try to access non-existent tournament
    visit organizer_tournament_path("non-existent-id")
    
    assert_current_path organizer_tournaments_path
    assert_text "Tournament not found"
  end
  
  test "handles double result submission gracefully" do
    organizer = users(:organizer_user)
    tournament = tournaments(:small_tournament_swiss)
    round = tournament.rounds.swiss_rounds.first
    pod = round.pods.first
    sign_in_as(organizer)
    
    # Submit result once
    visit organizer_round_path(round)
    
    within "[data-pod-id='#{pod.id}']" do
      winner = pod.tournament_participants.first
      select winner.player.user.name, from: "Winner"
      click_button "Submit Result"
    end
    
    assert_text "Result submitted successfully"
    
    # Try to submit again - should prevent or handle gracefully
    visit organizer_round_path(round)
    
    within "[data-pod-id='#{pod.id}']" do
      assert_no_button "Submit Result"
      assert_text "Result already submitted"
    end
  end
  
  test "handles concurrent tournament modifications" do
    organizer = users(:organizer_user)
    tournament = tournaments(:medium_tournament_registration_open)
    sign_in_as(organizer)
    
    # Simulate concurrent modification by updating tournament directly
    tournament.update!(status: "registration_closed")
    
    # Try to perform action that requires different state
    visit organizer_tournament_path(tournament)
    
    # Should show current state, not cached state
    assert_text "Registration Closed"
    assert_no_link "Close Registration"
  end
  
  test "validates tournament business rules in UI" do
    organizer = users(:organizer_user)
    sign_in_as(organizer)
    
    visit organizer_tournaments_path
    click_link "New Tournament"
    
    # Test max_participants validation
    fill_in "Name", with: "Test Tournament"
    fill_in "Max participants", with: "1000"
    click_button "Create Tournament"
    
    # Should show validation error for unrealistic max_participants
    assert_text "Max participants is too large"
    
    # Test date validation
    fill_in "Max participants", with: "16"
    select "2020", from: "tournament_date_1i"  # Past date
    click_button "Create Tournament"
    
    assert_text "Date cannot be in the past"
  end
  
  private
  
  def sign_in_as(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
  end
end