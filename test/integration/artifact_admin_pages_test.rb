require "test_helper"

class ArtifactAdminPagesTest < ActionDispatch::IntegrationTest
  setup { sign_in create_admin }

  def upload(type:, title:)
    ArtifactUploader.new.upload(
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
    assert_select "h1", "Photos"
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

  test "the annotations page embeds the editor payload" do
    artifact = upload(type: "PHOTO", title: "Group portrait")
    file = artifact.primary_file
    file.annotations.create!(annotation_text: "Grandmother", x_coord: 0.25, y_coord: 0.75)

    get annotations_admin_artifact_path(artifact)

    assert_response :success
    assert_select "#annotations-editor[data-payload]"
    assert_match "Grandmother", response.body
    assert_match "rails/active_storage", response.body
  end

  test "replacing a file's annotations creates, updates, and deletes in one request" do
    artifact = upload(type: "PHOTO", title: "Annotated")
    file = artifact.primary_file
    doomed = file.annotations.create!(annotation_text: "Old", x_coord: 0.1, y_coord: 0.1)
    kept = file.annotations.create!(annotation_text: "Keep", x_coord: 0.2, y_coord: 0.2)

    put "/api/artifact-files/#{file.id}/annotations", as: :json, params: {
      annotations: [
        { id: kept.id, annotationText: "Kept and renamed", xCoord: 0.2, yCoord: 0.2 },
        { id: nil, annotationText: "Brand new", xCoord: 0.5, yCoord: 0.5 }
      ]
    }

    assert_response :success
    texts = file.annotations.reload.map(&:annotation_text).sort
    assert_equal [ "Brand new", "Kept and renamed" ], texts
    assert_not file.annotations.exists?(doomed.id)
    assert_equal 2, response.parsed_body["annotations"].size
  end

  test "an out-of-range coordinate is rejected" do
    artifact = upload(type: "PHOTO", title: "Bounds")
    file = artifact.primary_file

    put "/api/artifact-files/#{file.id}/annotations", as: :json, params: {
      annotations: [ { annotationText: "off the image", xCoord: 1.5, yCoord: 0.5 } ]
    }

    assert_response :bad_request
    assert_equal 0, file.annotations.count
  end
end
