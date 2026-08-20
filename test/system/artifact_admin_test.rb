require "application_system_test_case"

class ArtifactAdminTest < ApplicationSystemTestCase
  FIXTURE = Rails.root.join("test/fixtures/files/artifact.png")

  def upload_photo(title:)
    ArtifactUploader.new.upload(
      files: [ Rack::Test::UploadedFile.new(FIXTURE, "image/png") ],
      artifact_type: "PHOTO", title: title
    )
  end

  test "uploading through the Uppy dashboard, then saving and adding another" do
    sign_in_as email: "boss@example.com", admin: true

    visit new_admin_artifact_path(type: "LETTER")
    assert_selector ".uppy-Dashboard"
    assert_equal "LETTER", find("#artifact_type").value

    attach_to_uppy FIXTURE
    assert_selector ".uppy-Dashboard-Item"

    click_on "Save and add another"
    assert_text "Artifact uploaded — add another"
    # The dashboard is cleared for the next run, and the type is kept.
    assert_no_selector ".uppy-Dashboard-Item"
    assert_equal "LETTER", find("#artifact_type").value
    assert_equal 1, Artifact.of_type("LETTER").count

    attach_to_uppy FIXTURE
    click_on "Upload", exact: true
    assert_selector "h1", text: "Untitled Letter"
    assert_current_path %r{/admin/artifacts/\d+}
    assert_equal 2, Artifact.of_type("LETTER").count
  end

  test "the annotations editor renders markers and saves a deletion" do
    artifact = upload_photo(title: "Group portrait")
    file = artifact.primary_file
    file.annotations.create!(annotation_text: "Grandmother", x_coord: 0.25, y_coord: 0.5)
    file.annotations.create!(annotation_text: "Grandfather", x_coord: 0.75, y_coord: 0.5)
    sign_in_as email: "boss@example.com", admin: true

    visit annotations_admin_artifact_path(artifact)
    assert_selector "[data-testid='annotation-marker']", count: 2

    # Deleting through the marker's popover needs no typing, so it exercises
    # the full edit-and-save loop without the chromedriver keystroke flake.
    # A real click first hovers, the hover opens the MUI tooltip, and the
    # tooltip then intercepts the click — so dispatch it directly.
    find("[data-testid='annotation-marker']", match: :first)
    page.execute_script("document.querySelector('[data-testid=annotation-marker]').click()")
    click_on "Delete"
    assert_text "Delete this annotation?"
    within(".MuiPopover-root") { click_on "Delete" }

    assert_text "Unsaved changes"
    click_on "Save annotations"
    assert_text "Annotations saved"

    assert_equal [ "Grandfather" ], file.annotations.reload.map(&:annotation_text)
    assert_selector "[data-testid='annotation-marker']", count: 1
  end

  test "adding a file through the details page and deleting it again" do
    artifact = upload_photo(title: "Stack of letters")
    sign_in_as email: "boss@example.com", admin: true

    visit admin_artifact_path(artifact)
    assert_text "The only file can't be deleted"

    attach_to_uppy FIXTURE
    click_on "Add files"
    assert_text "Files added."
    assert_equal [ 1, 2 ], artifact.reload.files.map(&:file_sequence)

    within("[data-testid='artifact-files']") do
      accept_confirm { all("button", text: "Delete").last.click }
    end
    assert_text "File deleted."
    assert_equal [ 1 ], artifact.reload.files.map(&:file_sequence)
    assert_text "The only file can't be deleted"
  end

  test "the typed collection pages appear in the aside nav" do
    upload_photo(title: "Wedding day")
    sign_in_as email: "boss@example.com", admin: true

    visit admin_root_path
    click_on "Photos"

    assert_selector "h1", text: "Photos"
    assert_text "Wedding day"
  end
end
