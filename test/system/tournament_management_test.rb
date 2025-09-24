# frozen_string_literal: true

require "application_system_test_case"

class TournamentManagementTest < ApplicationSystemTestCase
  test "organizer can create tournament with all fields" do
    organizer = users(:organizer_user)
    sign_in_as(organizer)
    
    visit organizer_tournaments_path
    click_link "New Tournament"
    
    fill_in "Name", with: "Grand Championship 2024"
    fill_in "Description", with: "The biggest tournament of the year"
    fill_in "Max participants", with: "32"
    fill_in "Address", with: "Lisboa, Portugal"
    select "2024", from: "tournament_date_1i"
    select "December", from: "tournament_date_2i"
    select "25", from: "tournament_date_3i"
    
    click_button "Create Tournament"
    
    assert_text "Tournament was successfully created"
    assert_text "Grand Championship 2024"
    
    tournament = Tournament.find_by(name: "Grand Championship 2024")
    assert_equal 32, tournament.max_participants
    assert_equal "draft", tournament.status
  end
  
  test "organizer can edit tournament details" do
    organizer = users(:organizer_user)
    tournament = tournaments(:small_tournament)
    sign_in_as(organizer)
    
    visit organizer_tournament_path(tournament)
    click_link "Edit Tournament"
    
    fill_in "Name", with: "Updated Tournament Name"
    fill_in "Description", with: "Updated description"
    
    click_button "Update Tournament"
    
    assert_text "Tournament was successfully updated"
    assert_text "Updated Tournament Name"
    
    tournament.reload
    assert_equal "Updated Tournament Name", tournament.name
  end
  
  test "organizer can manage tournament participants" do
    organizer = users(:organizer_user)
    tournament = tournaments(:medium_tournament_registration_open)
    sign_in_as(organizer)
    
    visit organizer_tournament_path(tournament)
    click_link "Manage Participants"
    
    assert_text "Tournament Participants"
    
    # Add participant manually
    click_link "Add Participant"
    
    select users(:player_one).name, from: "Player"
    click_button "Add Participant"
    
    assert_text "Participant added successfully"
    assert TournamentParticipant.exists?(
      tournament: tournament,
      player: users(:player_one).player
    )
  end
  
  test "organizer can submit penalties and infractions" do
    organizer = users(:organizer_user)
    tournament = tournaments(:small_tournament_swiss)
    participant = tournament.tournament_participants.first
    round = tournament.rounds.swiss_rounds.first
    sign_in_as(organizer)
    
    visit organizer_tournament_participant_path(participant)
    
    click_link "Add Infraction"
    
    select "Unsporting Conduct", from: "Type"
    fill_in "Description", with: "Player was rude to opponent"
    select round.name, from: "Round"
    
    click_button "Create Infraction"
    
    assert_text "Infraction created successfully"
    assert Infraction.exists?(
      tournament_participant: participant,
      infraction_type: "unsporting_conduct"
    )
    
    # Submit penalty result
    visit organizer_round_path(round)
    
    within "[data-participant-id='#{participant.id}']" do
      click_link "Add Penalty"
    end
    
    assert_text "Penalty added successfully"
    assert Penalty.exists?(
      tournament_participant: participant,
      round: round
    )
  end
  
  test "organizer can view comprehensive tournament reports" do
    organizer = users(:organizer_user)
    tournament = tournaments(:small_tournament_finished)
    sign_in_as(organizer)
    
    visit organizer_tournament_path(tournament)
    
    assert_text tournament.name
    assert_text "Finished"
    
    # View standings
    click_link "View Standings"
    
    assert_text "Final Standings"
    tournament.tournament_participants.each do |participant|
      assert_text participant.player.user.name
    end
    
    # View round details
    tournament.rounds.each_with_index do |round, index|
      visit organizer_tournament_path(tournament)
      click_link "Round #{index + 1}"
      
      assert_text "Round #{index + 1}"
      round.pods.each do |pod|
        pod.tournament_participants.each do |participant|
          assert_text participant.player.user.name
        end
      end
    end
  end
  
  test "registration limits are enforced" do
    tournament = tournaments(:small_tournament_registration_open)
    tournament.update!(max_participants: 2)
    
    # Fill tournament to capacity
    players = users.select { |u| u.player? }.first(2)
    players.each do |player|
      TournamentParticipant.create!(
        tournament: tournament,
        player: player.player
      )
    end
    
    # Try to register another player
    extra_player = users(:player_two)
    sign_in_as(extra_player)
    
    visit tournament_path(tournament)
    
    assert_no_link "Register"
    assert_text "Tournament is full"
  end
  
  private
  
  def sign_in_as(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
  end
end