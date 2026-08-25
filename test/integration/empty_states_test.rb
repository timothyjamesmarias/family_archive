require "test_helper"

class EmptyStatesTest < ActionDispatch::IntegrationTest
  test "a true-empty collection states it plainly, with no upload for visitors" do
    get "/ledgers"

    assert_match "No ledgers catalogued yet", response.body
    assert_match "waiting for its first scan", response.body
    assert_no_match(/Upload the first/, response.body)
  end

  test "signed-in admins get the upload action on a true-empty collection" do
    user = User.create!(name: "Admin", email: "admin@example.com", password: "password", admin: true)
    sign_in user

    get "/ledgers"

    assert_select "a.btn-primary", text: "Upload the first ledger"
  end

  test "a filtered-empty collection names the filters and offers the exit" do
    Artifact.create!(slug: "l1", artifact_type: "LETTER", title: "A letter")

    get "/letters", params: { q: "zeppelin", transcribed: "1" }

    assert_match "No letters match these filters", response.body
    assert_match "1 letters exist", response.body
    assert_select ".empty-state strong", text: "Transcribed"
    assert_select ".empty-state a", text: "Clear filters"
  end

  test "empty home bands collapse to a single line" do
    get root_path

    assert_match "Nothing catalogued yet &mdash; the first artifact will appear here.", response.body
    assert_match "Nothing published yet &mdash; the first article will appear here.", response.body
    assert_no_match(/All artifacts/, response.body)
  end
end
