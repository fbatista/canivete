# frozen_string_literal: true

require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign up successfully as player" do
    visit new_session_path
    click_link "Sign up"

    assert_current_path new_registration_path
    assert_text "Sign up"

    fill_in "user_name", with: "New Test User"
    fill_in "user_email_address", with: "newuser@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"

    click_button "Sign up"

    assert_current_path root_path
    assert_text "Welcome! You have signed up successfully."

    # Verify user was created and is signed in
    user = User.find_by(email_address: "newuser@example.com")
    assert_not_nil user
    assert_equal "New Test User", user.name
    assert_equal false, user.organizer?
    assert_not_nil user.player
    assert_text "Logout"
  end

  test "user can sign up successfully as organizer" do
    visit new_session_path
    click_link "Sign up"

    fill_in "user_name", with: "New Organizer"
    fill_in "user_email_address", with: "new_organizer@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"
    check "user_organizer"

    click_button "Sign up"

    assert_current_path root_path
    assert_text "Welcome! You have signed up successfully."

    # Verify organizer was created
    user = User.find_by(email_address: "new_organizer@example.com")
    assert_not_nil user
    assert_equal "New Organizer", user.name
    assert_equal true, user.organizer?
    assert_not_nil user.tournament_organizer
  end

  test "sign up validates required fields" do
    visit new_registration_path

    click_button "Sign up"

    assert_text "Please fix the following errors"
    assert_text "Name can't be blank"
    assert_text "Email address can't be blank"
    assert_text "Password can't be blank"
  end

  test "sign up validates password confirmation" do
    visit new_registration_path

    fill_in "user_name", with: "Test User"
    fill_in "user_email_address", with: "test@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "differentpassword"

    click_button "Sign up"

    assert_text "Password confirmation doesn't match Password"
  end

  test "user can sign in successfully" do
    user = users(:player_one)

    visit new_session_path

    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"

    click_button "Sign in"

    assert_current_path root_path
  end

  test "user can sign out successfully" do
    user = users(:player_one)
    sign_in_as(user)

    # Verify user is signed in
    assert_text "Logout"

    # Find and click the logout link using turbo-method delete
    click_link "Logout"

    # After logout, should see sign in form instead of logout
    assert_text "Sign in"
    assert_no_text "Logout"
  end

  test "user cannot sign in with invalid credentials" do
    visit new_session_path

    fill_in "email_address", with: "invalid@example.com"
    fill_in "password", with: "wrongpassword"

    click_button "Sign in"

    assert_text "Try another email address or password"
    assert_current_path new_session_path
  end

  test "user must be authenticated to access organizer area" do
    visit organizer_tournaments_path

    # Should redirect to sign in
    assert_current_path new_session_path
  end

  test "displays sign in form correctly" do
    visit new_session_path

    assert_text "Sign in"
    assert_field "email_address"
    assert_field "password"
    assert_button "Sign in"
    assert_link "Forgot password?"
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
  end
end
