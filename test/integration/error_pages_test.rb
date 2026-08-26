require "test_helper"

class ErrorPagesTest < ActionDispatch::IntegrationTest
  test "the 404 page offers search and the way back in" do
    get "/404"

    assert_response :not_found
    assert_match "404 &mdash; not found", response.body
    assert_select "h1", "Nothing is catalogued at this address"
    assert_match "the archive keeps everything", response.body
    assert_select "form[action='/search'] input[name='q']"
    assert_select "a", text: "All artifacts"
    assert_select "nav[aria-label='Primary']", count: 0
  end

  test "the 500 page states the fault plainly" do
    get "/500"

    assert_response :internal_server_error
    assert_match "500 &mdash; server error", response.body
    assert_select "h1", "Something failed on our side"
    assert_select "a.btn-secondary", text: "Back to home"
  end

  test "422 reuses the fault page with its own code" do
    get "/422"

    assert_response :unprocessable_content
    assert_match "422 &mdash; request rejected", response.body
  end

  test "a stale-token POST still gets the styled 422 page" do
    ActionController::Base.allow_forgery_protection = true
    post user_session_path, params: { user: { email: "x@y.z", password: "nope" } }

    assert_response :unprocessable_content
    assert_match "request rejected", response.body
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "an unpublished article renders the designed 404" do
    Article.create!(slug: "draft", title: "Unfinished", content: "<p>x</p>")

    get "/articles/draft"

    assert_response :not_found
  end
end
