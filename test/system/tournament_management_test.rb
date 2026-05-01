# frozen_string_literal: true

require "application_system_test_case"

class TournamentManagementTest < ApplicationSystemTestCase # rubocop:disable Metrics/ClassLength
  test "organizer can create tournament with all fields" do
    organizer = users(:organizer_user)
    sign_in_as(organizer)

    visit organizer_tournaments_path
    click_link "Organize Tournament"

    fill_in "Name", with: "Grand Championship 2024"
    fill_in "Description", with: "The biggest tournament of the year"
    fill_in "Maximum participants", with: "32"
    fill_in "Address", with: "Lisboa, Portugal"
    fill_in "Start time", with: Time.now.tomorrow.strftime("%Y-%m-%dT%H:%M")
    fill_in "End time", with: Time.now.tomorrow.strftime("%Y-%m-%dT%H:%M")

    click_button "Create Tournament"

    # Verify tournament was created
    tournament = Tournament.find_by(name: "Grand Championship 2024")
    assert_not_nil tournament
    assert_equal "registration_open", tournament.state
  end

  test "organizer can edit tournament details" do
    organizer = users(:organizer_user)
    tournament = events(:small_tournament)
    sign_in_as(organizer)

    visit organizer_tournament_path(tournament)
    click_link "Edit"

    fill_in "Name", with: "Updated Tournament Name"
    fill_in "Description", with: "Updated description"

    click_button "Update"

    tournament.reload
    assert_equal "Updated Tournament Name", tournament.name
  end

  test "organizer can manage tournament participants" do
    organizer = users(:organizer_user)
    tournament = events(:medium_tournament_registration_open)
    sign_in_as(organizer)

    visit organizer_tournament_path(tournament)
    click_link "Players"

    assert_text "Participants"

    # Add participant manually via modal form
    click_link "Add player"

    fill_in "Player email", with: "player1@example.com"
    fill_in "Player name", with: users(:player_one).name
    fill_in "Decklist", with: "https://moxfield.com/test"
    check "Player has read and accepted event rules"
    click_button "Create Event participant"

    assert EventParticipant.exists?(
      event: tournament,
      player: users(:player_one).player
    )
  end

  test "organizer can submit penalties and infractions" do
    organizer = users(:organizer_user)
    tournament = events(:small_tournament)
    participant = tournament.event_participants.first
    sign_in_as(organizer)

    # Navigate to infraction creation page
    visit new_organizer_tournament_infraction_path(tournament, player_id: participant.player_id)

    # Select matching kind, category, and penalty
    select "Unsporting Conduct", from: "Kind"
    select "Minor", from: "Category"
    select "Warning", from: "Penalty"
    fill_in "Description", with: "Player was rude to opponent"

    click_button "Record Infraction"

    assert_text "Infraction added successfully"
    assert Infraction.exists?(
      player: participant.player,
      kind: "unsporting_conduct"
    )
  end

  test "organizer can view comprehensive tournament reports" do
    organizer = users(:organizer_user)
    tournament = events(:finished_tournament)
    sign_in_as(organizer)

    visit organizer_tournament_path(tournament)

    assert_text tournament.name
    assert_text "Finished"

    # View standings via Participants
    click_link "Players"

    assert_text "Participants"
    tournament.event_participants.each do |participant|
      assert_text participant.player.user.name
    end

    # View round details
    tournament.rounds.each_with_index do |round, index|
      visit organizer_tournament_path(tournament)
      click_link "Bracket"

      assert_text "Round #{index + 1}"
      round.pods.each do |pod|
        pod.event_participants.each do |participant|
          assert_text participant.player.user.name
        end
      end
    end
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "session_email_address", with: user.email_address
    fill_in "session_password", with: "password123"
    click_button "Sign in"
  end
end
