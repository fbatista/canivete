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
    assert_not_nil user.event_organizer
  end

  test "sign up validates required fields" do
    visit new_registration_path

    click_button "Sign up"

    # Form re-renders with validation errors (required badges prove re-render)
    assert_current_path new_registration_path
    assert_text "Sign up"
    # Fields still present and required
    assert_field "user_name", disabled: false
    assert_field "user_email_address", disabled: false
    assert_field "user_password", disabled: false
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

    fill_in "session_email_address", with: user.email_address
    fill_in "session_password", with: "password123"

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

    # After logout, should see log in text instead of logout
    assert_text "Log in"
    assert_no_text "Logout"
  end

  test "user cannot sign in with invalid credentials" do
    visit new_session_path

    fill_in "session_email_address", with: "invalid@example.com"
    fill_in "session_password", with: "wrongpassword"

    click_button "Sign in"

    assert_current_path new_session_path
    assert_text "Sign in"
  end

  test "user must be authenticated to access organizer area" do
    visit organizer_tournaments_path

    # Should redirect to sign in
    assert_current_path new_session_path
  end

  test "displays sign in form correctly" do
    visit new_session_path

    assert_text "Sign in"
    assert_field "session_email_address"
    assert_field "session_password"
    assert_button "Sign in"
    assert_link "Forgot password?"
  end

  test "forgot password modal cancel button stays inline" do
    visit root_path

    find("nav a", text: "Log in").click
    assert_selector "turbo-frame#modal"

    click_on "Forgot password?"
    assert_text "Forgot your password?"

    click_on "Cancel"

    assert_text "Sign in"
    assert_field "session_email_address"
    assert_selector "a", text: "Log in"
  end

  test "sign in modal cancel button closes the modal" do
    visit root_path

    assert_selector "a", text: "Log in"
    find("nav a", text: "Log in").click

    assert_selector "turbo-frame#modal"
    assert_text "Sign in"
    assert_field "session_email_address"

    click_on "Cancel"

    assert_no_field "session_email_address"
    assert_no_text "Sign in"
    assert_no_text "Forgot password?"
  end

  test "successful sign in closes modal and refreshes page" do
    visit root_path

    find("nav a", text: "Log in").click
    fill_in "session_email_address", with: users(:player_one).email_address
    fill_in "session_password", with: "password123"
    click_button "Sign in"

    assert_no_text "Log in"
    assert_text "Logout"
  end

  test "successful sign up logs in user and refreshes page" do
    visit root_path

    find("nav a", text: "Log in").click
    click_on "Sign up"

    fill_in "user_name", with: "New Test User"
    fill_in "user_email_address", with: "newuser@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"
    click_button "Sign up"

    assert_text "Welcome! You have signed up successfully."
    assert_no_text "Log in"
    assert_text "Logout"
  end

  private

  def sign_in_as(user)
    visit root_path
    visit new_session_path
    fill_in "session_email_address", with: user.email_address
    fill_in "session_password", with: "password123"
    click_button "Sign in"
  end
end
