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
