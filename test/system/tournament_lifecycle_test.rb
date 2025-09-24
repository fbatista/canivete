# frozen_string_literal: true

require "application_system_test_case"

class TournamentLifecycleTest < ApplicationSystemTestCase
  test "organizer can create and manage complete tournament lifecycle" do
    organizer = users(:organizer_user)
    sign_in_as(organizer)
    
    # Create tournament
    visit organizer_tournaments_path
    click_link "New Tournament"
    
    fill_in "Name", with: "Test Championship"
    fill_in "Description", with: "A test tournament for system testing"
    fill_in "Max participants", with: "16"
    fill_in "Address", with: "Porto, Portugal"
    
    click_button "Create Tournament"
    
    assert_text "Tournament was successfully created"
    tournament = Tournament.find_by(name: "Test Championship")
    assert_equal "draft", tournament.status
    
    # Open registration
    click_link "Open Registration"
    
    assert_text "Registration opened successfully"
    tournament.reload
    assert_equal "registration_open", tournament.status
    
    # Simulate player registrations (using direct model calls for speed)
    players = users.select { |u| u.player? }.first(6)
    players.each do |player|
      TournamentParticipant.create!(
        tournament: tournament,
        player: player.player
      )
    end
    
    # Close registration and start Swiss rounds
    visit organizer_tournament_path(tournament)
    click_link "Close Registration"
    
    assert_text "Registration closed successfully"
    tournament.reload
    assert_equal "registration_closed", tournament.status
    
    click_link "Start Swiss Rounds"
    
    assert_text "Swiss rounds started successfully"
    tournament.reload
    assert_equal "swiss", tournament.status
    assert tournament.rounds.swiss_rounds.any?
    
    # Verify pods were created
    first_round = tournament.rounds.swiss_rounds.first
    visit organizer_round_path(first_round)
    
    assert_text "Round 1"
    assert first_round.pods.any?
    
    # Submit results for all pods
    first_round.pods.each do |pod|
      winner = pod.tournament_participants.first
      
      visit organizer_round_path(first_round)
      within "[data-pod-id='#{pod.id}']" do
        select winner.player.user.name, from: "Winner"
        click_button "Submit Result"
      end
      
      assert_text "Result submitted successfully"
    end
    
    # Finish the round
    click_link "Finish Round"
    
    assert_text "Round finished successfully"
    first_round.reload
    assert_equal "finished", first_round.status
    
    # Start single elimination if applicable
    if tournament.number_of_single_elimination_rounds > 0
      click_link "Start Single Elimination"
      
      assert_text "Single elimination started successfully"
      tournament.reload
      assert_equal "single_elimination", tournament.status
    end
    
    # Finish tournament
    visit organizer_tournament_path(tournament)
    click_link "Finish Tournament"
    
    assert_text "Tournament finished successfully"
    tournament.reload
    assert_equal "finished", tournament.status
  end
  
  test "player can register for tournament and view results" do
    tournament = tournaments(:medium_tournament_registration_open)
    player_user = users(:player_one)
    sign_in_as(player_user)
    
    # Register for tournament
    visit tournament_path(tournament)
    click_link "Register"
    
    assert_text "Successfully registered for tournament"
    assert TournamentParticipant.exists?(
      tournament: tournament,
      player: player_user.player
    )
    
    # View tournament details
    assert_text tournament.name
    assert_text "Registration Open"
    
    # After tournament starts, view results
    tournament.update!(status: "swiss")
    visit tournament_path(tournament)
    
    assert_text "Swiss Rounds"
    if tournament.rounds.any?
      click_link "View Round 1"
      assert_text "Round 1"
    end
  end
  
  test "tournament cancellation flow works correctly" do
    organizer = users(:organizer_user)
    tournament = tournaments(:small_tournament)
    sign_in_as(organizer)
    
    visit organizer_tournament_path(tournament)
    
    accept_confirm do
      click_link "Cancel Tournament"
    end
    
    assert_text "Tournament cancelled successfully"
    tournament.reload
    assert_equal "cancelled", tournament.status
  end
  
  private
  
  def sign_in_as(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
  end
end