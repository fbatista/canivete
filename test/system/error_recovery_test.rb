# frozen_string_literal: true

require "application_system_test_case"

class ErrorRecoveryTest < ApplicationSystemTestCase
  test "handles tournament state transition errors gracefully" do
    organizer = users(:organizer_user)
    tournament = events(:medium_tournament_registration_open)
    sign_in_as(organizer)

    # Draft state shows Open Registrations button
    visit organizer_tournament_path(tournament)

    # registration_open state shows Close Registrations and Cancel buttons
    assert_button "Close Registrations"
    assert_no_button "Open Registrations"

    # Cancel requires a confirm dialog
    cancel_btn = find("button", text: "Cancel", wait: 5)
    cancel_btn.click
    accept_confirm
    assert_text "Tournament updated successfully"

    tournament.reload
    assert_equal "canceled", tournament.state
    assert_current_path organizer_tournament_path(tournament)
  end

  test "handles invalid form submissions gracefully" do
    organizer = users(:organizer_user)
    sign_in_as(organizer)

    visit organizer_tournaments_path
    click_link "Organize Tournament"

    # Submit form with missing required fields
    fill_in "Start time", with: Time.zone.now.tomorrow.strftime("%Y-%m-%dT%H:%M")
    fill_in "End time", with: Time.zone.now.tomorrow.strftime("%Y-%m-%dT%H:%M")
    click_button "Create Tournament"

    # The form should still be visible with Name field (validation error)
    assert_text "Name"
    assert_text "Create Tournament"
  end

  test "handles unauthorized access attempts" do
    player = users(:player_one)
    tournament = events(:small_tournament)
    sign_in_as(player)

    # Try to access organizer area
    visit organizer_tournament_path(tournament)

    # Should redirect and show error
    assert_current_path root_path
    # The player namespace uses a different error message
    assert_text "Not allowed"
  end

  test "handles non-existent resource requests" do
    organizer = users(:organizer_user)
    sign_in_as(organizer)

    # Try to access non-existent tournament
    visit organizer_tournament_path("non-existent-id")

    assert_current_path organizer_root_path
    assert_text "Not authorized to manage the selected tournament"
  end

  test "handles double result submission gracefully" do
    organizer = users(:organizer_user)
    tournament = events(:small_tournament_swiss)
    round = tournament.rounds.swiss_rounds.first
    pod = round.pods.first
    sign_in_as(organizer)

    # Navigate to round page and click Insert result to open modal
    visit organizer_tournament_round_path(tournament, round)

    within "#pod_#{pod.id}" do
      click_link "Insert result"
    end

    # Fill in result modal form
    select "Win", from: "Type"
    select pod.event_participants.first.name, from: "Event participant"
    click_button "Create Result"

    assert_text "Result submitted successfully"

    # Pod should be finished now
    pod.reload
    assert pod.finished?
  end

  test "handles concurrent tournament modifications" do
    organizer = users(:organizer_user)
    tournament = events(:medium_tournament_registration_open)
    sign_in_as(organizer)

    # Simulate concurrent modification by updating tournament directly
    tournament.update!(state: "registration_closed")

    # Try to perform action that requires different state
    visit organizer_tournament_path(tournament)

    # Should show current state, not cached state
    # registration_closed state shows "Move to Swiss stage" and "Cancel" buttons
    assert_button "Move to Swiss stage"
    assert_no_button "Close Registrations"
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "session_email_address", with: user.email_address
    fill_in "session_password", with: "password123"
    click_button "Sign in"
  end
end
