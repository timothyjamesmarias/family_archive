require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # The first browser interaction in a run waits on Vite serving assets, which
  # exceeds Capybara's 2s default.
  Capybara.default_max_wait_time = 10

  def sign_in_as(email: "member@example.com", password: "password123", admin: false)
    User.create!(email: email, password: password, name: "Test User", admin: admin)

    visit new_user_session_path
    fill_verified "user_email", email
    fill_verified "user_password", password
    page.execute_script("document.getElementById('user_password').form.requestSubmit()")

    assert_no_current_path new_user_session_path
  end

  private

  # Chromedriver intermittently eats synthesized keystrokes on this page (the
  # value reads back empty even to Capybara), and the form then blocks its own
  # submit on the empty required field. The login form is plain HTML with no
  # input listeners, so writing the value directly is equivalent and immune.
  def fill_verified(id, value)
    find_by_id(id) # wait for the element before scripting against it
    10.times do
      page.execute_script(<<~JS)
        const el = document.getElementById(#{id.to_json});
        el.value = #{value.to_json};
        el.dispatchEvent(new Event("input", { bubbles: true }));
        el.dispatchEvent(new Event("change", { bubbles: true }));
      JS
      return if page.evaluate_script("document.getElementById(#{id.to_json}).value") == value

      sleep 0.2
    end
    flunk "could not fill ##{id}"
  end
end
