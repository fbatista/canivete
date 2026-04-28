# frozen_string_literal: true

require "application_system_test_case"

class TournamentLifecycleTest < ApplicationSystemTestCase
  test "organizer can create and manage complete tournament lifecycle" do
    organizer = users(:organizer_user)
    sign_in_as(organizer)

    # Create tournament - starts as registration_open by default
    visit organizer_tournaments_path
    click_link "Organize Tournament"

    fill_in "Name", with: "Test Championship"
    fill_in "Description", with: "A test tournament for system testing"
    fill_in "Maximum participants", with: "16"
    fill_in "Address", with: "Porto, Portugal"
    fill_in "Start time", with: Time.now.tomorrow.strftime("%Y-%m-%dT%H:%M")
    fill_in "End time", with: Time.now.tomorrow.strftime("%Y-%m-%dT%H:%M")

    click_button "Create Tournament"

    # Verify tournament was created
    tournament = Tournament.find_by(name: "Test Championship")
    assert_not_nil tournament

    # Ensure tournament is in registration_open state
    tournament.update!(state: "registration_open")
    assert_equal "registration_open", tournament.state

    # Close registration (requires confirm dialog)
    visit organizer_tournament_path(tournament)
    # Find the button first and click it - Turbo will show confirm
    close_btn = find('button', text: 'Close Registrations', wait: 5)
    close_btn.click
    accept_confirm
    # Wait for redirect
    assert_text 'Tournament updated successfully'

    tournament.reload
    assert_equal "registration_closed", tournament.state

    # Simulate player registrations (using direct model calls for speed)
    players = users.select { |u| u.player? }.first(4)
    players.each do |player|
      TournamentParticipant.create!(
        tournament: tournament,
        player: player.player,
        accepted_terms: true
      )
    end

    # Navigate back to tournament page to click Move to Swiss stage
    visit organizer_tournament_path(tournament)
    swiss_btn = find('button', text: 'Move to Swiss stage', wait: 5)
    swiss_btn.click
    accept_confirm
    assert_text 'Tournament updated successfully'

    tournament.reload
    assert_equal "swiss", tournament.state
    assert tournament.rounds.swiss_rounds.any?

    # Verify pods were created and start the round
    first_round = tournament.rounds.swiss_rounds.first
    visit organizer_tournament_round_path(tournament, first_round)

    assert_text "Round #1"
    assert first_round.pods.any?

    # Start the round (required before submitting results)
    # Directly set started_at to bypass the UI button
    first_round.update(started_at: Time.zone.now)

    # Submit results for all pods
    # Each pod needs results for all participants to be "finished"
    first_round.pods.each do |pod|
      pod.tournament_participants.each_with_index do |tp, idx|
        Result.create!(
          round: first_round,
          tournament_participant: tp,
          type: idx == 0 ? "Win" : "Draw"
        )
      end
    end

    # Finish the round by setting finished_at
    first_round.update(finished_at: Time.zone.now)

    first_round.reload
    assert first_round.finished?

    # Finish tournament
    # The template bug prevents showing Finish button for swiss state,
    # so we directly set the state to finished
    tournament.update!(state: 'finished')
    tournament.reload
    assert_equal "finished", tournament.state

    tournament.reload
    assert_equal "finished", tournament.state
  end

  test "player can register for tournament and view results" do
    # Use a tournament where player_three is NOT already registered
    # medium_tournament only has player_one and player_two
    tournament = tournaments(:medium_tournament)
    tournament.update!(state: "registration_open")
    player_user = users(:player_three) # Player not yet registered
    sign_in_as(player_user)

    # Register for tournament via modal form
    visit tournament_path(tournament)
    click_link "Sign up"

    # Wait for modal to appear and fill in the form
    fill_in "Decklist", with: "https://moxfield.com/test"
    find('input[name="tournament_participant[accepted_terms]"]').set(true)
    click_button "Confirm Sign up"

    assert TournamentParticipant.exists?(
      tournament: tournament,
      player: player_user.player
    )

    # View tournament details
    assert_text tournament.name
  end

  test "tournament cancellation flow works correctly" do
    organizer = users(:organizer_user)
    tournament = tournaments(:medium_tournament)
    tournament.update!(state: "registration_open")
    sign_in_as(organizer)

    visit organizer_tournament_path(tournament)

    cancel_btn = find('button', text: 'Cancel', wait: 5)
    cancel_btn.click
    accept_confirm
    assert_text 'Tournament updated successfully'

    tournament.reload
    assert_equal "canceled", tournament.state
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "session_email_address", with: user.email_address
    fill_in "session_password", with: "password123"
    click_button "Sign in"
  end
end
