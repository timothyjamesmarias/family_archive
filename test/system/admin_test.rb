require "application_system_test_case"

class AdminTest < ApplicationSystemTestCase
  test "a signed-in non-admin is turned away" do
    sign_in_as email: "member@example.com"

    visit admin_root_path

    assert_current_path root_path
  end

  test "an admin reaches the dashboard" do
    sign_in_as email: "boss@example.com", admin: true

    visit admin_root_path

    assert_selector "h1", text: "Overview"
    assert_selector "[data-testid='current-user']", text: "boss@example.com"
  end
end
