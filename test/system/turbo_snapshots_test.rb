require "application_system_test_case"

# Turbo Drive restores Back/Forward from snapshots of the page as it was left;
# these guard the state that must not come back with it.
class TurboSnapshotsTest < ApplicationSystemTestCase
  test "a flash message does not reappear on Back" do
    sign_in_as email: "member@example.com"
    visit admin_root_path
    assert_selector "[data-testid='flash-alert']", text: "Not authorized."

    # Chromedriver intermittently drops this click (CI has failed with the
    # page still on home), so drive the same Turbo visit the link would.
    page.execute_script("Turbo.visit(#{articles_path.to_json})")
    assert_selector "h1", text: "Articles"
    go_back

    assert_link "Browse the collections"
    assert_no_selector "[data-testid='flash-alert']"
  end

  test "Back to a recording shows the speed its fresh media element plays at" do
    artifact = Artifact::Uploader.new.upload(
      files: [ Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/artifact.png"), "audio/wav") ],
      artifact_type: "AUDIO", title: "Interview"
    )
    visit "/audio/#{artifact.slug}"
    click_on "1×", exact: true
    assert_button "1.25×", exact: true

    click_on "Audio Recordings"
    assert_selector "h1", text: "Audio Recordings"
    go_back

    assert_selector "h1", text: "Interview"
    assert_button "1×", exact: true
  end
end
