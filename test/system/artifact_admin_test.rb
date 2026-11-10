require "application_system_test_case"

class ArtifactAdminTest < ApplicationSystemTestCase
  FIXTURE = Rails.root.join("test/fixtures/files/artifact.png")

  def upload_photo(title:)
    Artifact::Uploader.new.upload(
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

  test "Turbo history navigation leaves the upload page with one dashboard" do
    sign_in_as email: "boss@example.com", admin: true
    visit admin_artifacts_path
    # Survives only if every navigation below stays a Turbo visit.
    page.execute_script("window.turboVisitMarker = true")

    click_on "Upload artifact"
    assert_selector "h1", text: "Upload artifact"
    assert_selector ".uppy-Dashboard", count: 1

    go_back
    assert_no_selector ".uppy-Dashboard"
    go_forward
    assert_selector "h1", text: "Upload artifact"
    assert_selector ".uppy-Dashboard", count: 1
    assert page.evaluate_script("window.turboVisitMarker")
  end

  test "deleting an annotation from its marker's popover" do
    artifact = upload_photo(title: "Group portrait")
    file = artifact.primary_file
    file.annotations.create!(annotation_text: "Grandmother", x_coord: 0.25, y_coord: 0.5)
    file.annotations.create!(annotation_text: "Grandfather", x_coord: 0.75, y_coord: 0.5)
    sign_in_as email: "boss@example.com", admin: true

    visit annotations_admin_artifact_path(artifact)
    assert_selector "[data-photo-annotations-target='marker']", count: 2

    # Deletion needs no typing, so it exercises the popover-and-morph loop
    # without the chromedriver keystroke flake; typing is covered by the
    # integration tests.
    # The fixture image is a few pixels wide, so marker 2 sits on top of 1.
    find("[aria-label='Annotation 2']").click
    within("turbo-frame#annotation_form") do
      assert_text "Edit annotation"
      accept_confirm { click_on "Delete" }
    end

    assert_text "Annotation deleted."
    assert_selector "[data-photo-annotations-target='marker']", count: 1
    assert_no_selector "turbo-frame#annotation_form form"
    assert_equal [ "Grandmother" ], file.annotations.reload.map(&:annotation_text)
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
    click_on "Photographs"

    assert_selector "h1", text: "Photographs"
    assert_text "Wedding day"
  end
end
