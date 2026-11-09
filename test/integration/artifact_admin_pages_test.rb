require "test_helper"

class ArtifactAdminPagesTest < ActionDispatch::IntegrationTest
  setup { sign_in create_admin }

  def upload(type:, title:)
    Artifact::Uploader.new.upload(
      files: [ fixture_file_upload("artifact.png", "image/png") ],
      artifact_type: type, title: title
    )
  end

  test "a typed collection page lists only artifacts of that type" do
    upload(type: "PHOTO", title: "Wedding day")
    upload(type: "LETTER", title: "Dear John")

    get admin_typed_artifacts_path("photos")

    assert_response :success
    assert_match "Wedding day", response.body
    assert_no_match "Dear John", response.body
    assert_select "h1", "Photographs"
  end

  test "the aside nav links every artifact type page" do
    get admin_artifacts_path

    ArtifactType::ALL.each do |type|
      assert_select "a[href=?]", admin_typed_artifacts_path(type.route_segment)
    end
  end

  test "uploading as JSON returns the new artifact's id" do
    post admin_artifacts_path(format: :json), params: {
      files: [ fixture_file_upload("artifact.png", "image/png") ],
      artifact: { artifact_type: "PHOTO", title: "From Uppy" }
    }

    assert_response :created
    artifact = Artifact.find_by!(title: "From Uppy")
    assert_equal artifact.id, response.parsed_body.dig("data", "id")
  end

  test "a JSON upload with a disallowed file reports the error" do
    post admin_artifacts_path(format: :json), params: {
      files: [ fixture_file_upload("script.sh", "application/x-sh") ],
      artifact: { artifact_type: "PHOTO" }
    }

    assert_response :unprocessable_entity
    assert_match(/not an allowed file type/, response.parsed_body.dig("errors", "files"))
  end

  test "the annotations page renders markers and list rows" do
    artifact = upload(type: "PHOTO", title: "Group portrait")
    file = artifact.primary_file
    annotation = file.annotations.create!(annotation_text: "Grandmother", x_coord: 0.25, y_coord: 0.75)

    get annotations_admin_artifact_path(artifact)

    assert_response :success
    assert_select "a[data-photo-annotations-target=marker][href=?][style*='left: 25.0%']",
                  edit_admin_artifact_file_annotation_path(file, annotation), text: "1"
    assert_select "[data-photo-annotations-target=row]", text: /Grandmother/
    assert_match "rails/active_storage", response.body
  end
end
