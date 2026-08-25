require "test_helper"

class LoginPageTest < ActionDispatch::IntegrationTest
  test "the sign-in card renders with minimal chrome" do
    get new_user_session_path

    assert_response :success
    assert_select "h1", "Sign in"
    assert_match "Browsing the archive needs no account", response.body
    assert_match "Accounts are created by the archive admins", response.body
    assert_select "a", text: "Forgot password"
    assert_select "nav[aria-label='Primary']", count: 0
    assert_select "input#user_email.field-input"
    assert_select "input[type='submit'][value='Sign in']"
  end

  test "a failed attempt shows the error inside the card, once" do
    User.create!(name: "Admin", email: "admin@example.com", password: "password", admin: true)

    post user_session_path, params: { user: { email: "admin@example.com", password: "wrong" } }

    assert_response :unprocessable_content
    assert_select ".message-error .message-label", text: "Error", count: 1
  end
end
