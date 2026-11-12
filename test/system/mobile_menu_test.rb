require "application_system_test_case"

class MobileMenuTest < ApplicationSystemTestCase
  # Its own driver name: unnamed, Rails registers this as :selenium, the same
  # name as the 1400px driver, and Capybara reuses whichever browser started first.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ],
    options: { name: :headless_chrome_phone }

  test "the menu opens from its button and Escape closes it" do
    visit root_path
    assert_no_selector "#mobile-menu"

    find("button[aria-label='Toggle menu']").click
    within("#mobile-menu") { assert_link "Articles" }
    assert_selector "button[aria-label='Toggle menu'][aria-expanded='true']"

    # Chromedriver can eat synthesized keystrokes (see fill_verified), so the
    # Escape is dispatched the way a real one arrives.
    page.execute_script(<<~JS)
      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }))
    JS
    assert_no_selector "#mobile-menu"
    assert_selector "button[aria-label='Toggle menu'][aria-expanded='false']"
  end

  test "Back after following a menu link restores the page with the menu closed" do
    visit root_path
    find("button[aria-label='Toggle menu']").click
    within("#mobile-menu") { click_on "Articles" }
    assert_selector "h1", text: "Articles"

    go_back

    assert_link "Browse the collections"
    assert_no_selector "#mobile-menu"
    assert_selector "button[aria-label='Toggle menu'][aria-expanded='false']"
  end
end
