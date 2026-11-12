require "application_system_test_case"

class DarkModeTest < ApplicationSystemTestCase
  # Headless Chrome reports prefers-color-scheme: dark, so pin the stored
  # theme instead of assuming what a fresh visit starts as.
  def force_light_theme
    page.execute_script("localStorage.setItem('theme', 'light')")
  end

  test "the admin toggle flips the theme and it persists across pages" do
    sign_in_as email: "boss@example.com", admin: true
    visit admin_root_path
    force_light_theme
    visit admin_root_path
    assert_no_selector "html.dark"

    find("button[aria-label='Toggle dark mode']").click
    assert_selector "html.dark"

    visit admin_artifacts_path
    assert_selector "html.dark"

    find("button[aria-label='Toggle dark mode']").click
    assert_no_selector "html.dark"
  end

  test "the public toggle works through the same controller" do
    visit root_path
    force_light_theme
    visit root_path
    assert_no_selector "html.dark"

    first("button[aria-label='Toggle dark mode']").click
    assert_selector "html.dark"

    # A Turbo visit swaps the body under the <html> that carries the class.
    page.execute_script("window.turboVisitMarker = true")
    within("nav[aria-label='Primary']", match: :first) { click_on "Articles" }
    assert_selector "h1", text: "Articles"
    assert_selector "html.dark"

    first("button[aria-label='Toggle dark mode']").click
    assert_no_selector "html.dark"
    assert page.evaluate_script("window.turboVisitMarker")
  end
end
