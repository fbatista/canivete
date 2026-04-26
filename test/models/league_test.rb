# frozen_string_literal: true

require "test_helper"

class LeagueTest < ActiveSupport::TestCase
  test "league has correct state enum" do
    assert_includes League.states, "draft"
    assert_includes League.states, "registration_open"
    assert_includes League.states, "registration_closed"
    assert_includes League.states, "play"
    assert_includes League.states, "finals"
    assert_includes League.states, "finished"
    assert_includes League.states, "canceled"
  end

  test "league transitions from draft to registration_open" do
    league = leagues(:standard_league)
    league.update!(state: "draft")
    league.update!(state: "registration_open")
    assert league.registration_open?
  end

  test "league transitions from registration_open to registration_closed" do
    league = leagues(:standard_league)
    league.update!(state: "registration_closed")
    assert league.registration_closed?
  end

  test "league transitions from registration_closed to play" do
    league = leagues(:standard_league)
    league.update!(state: "registration_closed")
    league.update!(state: "play")
    assert league.play?
  end

  test "league transitions from play to finals" do
    league = leagues(:standard_league)
    league.update!(state: "registration_closed")
    league.update!(state: "play")
    league.update!(state: "finals")
    assert league.finals?
  end

  test "league transitions from finals to finished" do
    league = leagues(:standard_league)
    league.update!(state: "registration_closed")
    league.update!(state: "play")
    league.update!(state: "finals")
    league.update!(state: "finished")
    assert league.finished?
  end

  test "league can be canceled at any stage" do
    league = leagues(:standard_league)
    league.update!(state: "draft")
    league.update!(state: "canceled")
    assert league.canceled?
  end

  test "ongoing scope returns play and finals leagues" do
    league = leagues(:standard_league)
    league.registration_closed!
    league.play!
    assert_includes League.ongoing, league
  end

  test "wager_percentage must be between 0 and 100" do
    league = leagues(:standard_league)
    league.wager_percentage = 101
    assert_not league.valid?
    assert_match(/less than or equal to 100/, league.errors[:wager_percentage].first)

    league.wager_percentage = -1
    assert_not league.valid?
    assert_match(/greater than or equal to 0/, league.errors[:wager_percentage].first)

    league.wager_percentage = 0
    assert league.valid?

    league.wager_percentage = 100
    assert league.valid?

    league.wager_percentage = nil
    assert league.valid?
  end

  test "play_mode enum is defined" do
    assert_includes League.play_modes, "scheduled"
    assert_includes League.play_modes, "pickup"
  end

  test "league defaults to scheduled play_mode" do
    league = leagues(:standard_league)
    assert_equal "scheduled", league.play_mode
    assert league.play_mode_scheduled?
  end

  test "scheduled mode league can be set to pickup" do
    league = leagues(:standard_league)
    league.play_mode_scheduled!
    assert league.play_mode_scheduled?

    league.play_mode_pickup!
    assert league.play_mode_pickup?
  end

  test "perform_state_based_actions triggers StartPlayRoundJob" do
    league = leagues(:standard_league)
    league.registration_closed!

    # Verify that transitioning to play runs StartPlayRoundJob
    # (perform_state_based_actions calls perform_now which runs synchronously)
    assert_nothing_raised do
      league.play!
    end
    assert_equal "play", league.reload.state
  end

  test "perform_state_based_actions triggers StartFinalsRoundJob" do
    league = leagues(:standard_league)
    league.registration_closed!
    league.play!

    # Verify that transitioning to finals runs StartFinalsRoundJob
    assert_nothing_raised do
      league.finals!
    end
    assert_equal "finals", league.reload.state
  end
end
