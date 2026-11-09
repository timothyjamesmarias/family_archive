require "test_helper"

class AdminAnnotationsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in create_admin
    artifact = Artifact::Uploader.new.upload(
      files: [ fixture_file_upload("artifact.png", "image/png") ], artifact_type: "PHOTO", title: "Portrait"
    )
    @file = artifact.primary_file
    @editor = annotations_admin_artifact_path(artifact, file: @file.id)
  end

  test "the new form carries the clicked coordinates" do
    get new_admin_artifact_file_annotation_path(@file, x: 0.3, y: 0.6)

    assert_response :success
    assert_select "input[type=hidden][name='annotation[x_coord]'][value='0.3']"
    assert_select "input[type=hidden][name='annotation[y_coord]'][value='0.6']"
  end

  test "creating an annotation returns to the editor" do
    post admin_artifact_file_annotations_path(@file), params: {
      annotation: { annotation_text: "Grandmother", x_coord: 0.25, y_coord: 0.75 }
    }

    assert_redirected_to @editor
    annotation = @file.annotations.sole
    assert_equal [ "Grandmother", 0.25, 0.75 ], [ annotation.annotation_text, annotation.x_coord, annotation.y_coord ]
  end

  test "updating an annotation's text" do
    annotation = @file.annotations.create!(annotation_text: "Old", x_coord: 0.1, y_coord: 0.1)

    patch admin_artifact_file_annotation_path(@file, annotation), params: { annotation: { annotation_text: "New" } }

    assert_redirected_to @editor
    assert_equal "New", annotation.reload.annotation_text
  end

  test "deleting an annotation" do
    annotation = @file.annotations.create!(annotation_text: "Doomed", x_coord: 0.1, y_coord: 0.1)

    delete admin_artifact_file_annotation_path(@file, annotation)

    assert_redirected_to @editor
    assert_not Annotation.exists?(annotation.id)
  end

  test "an invalid annotation re-renders the form with its errors" do
    post admin_artifact_file_annotations_path(@file), params: {
      annotation: { annotation_text: "", x_coord: 1.5, y_coord: 0.5 }
    }

    assert_response :unprocessable_entity
    assert_match "Annotation text can&#39;t be blank", response.body
    assert_match "X coord must be in 0..1", response.body
    assert_equal 0, @file.annotations.count
  end

  test "an annotation is only reachable through its own file" do
    other = Artifact::Uploader.new.upload(
      files: [ fixture_file_upload("artifact.png", "image/png") ], artifact_type: "PHOTO"
    ).primary_file
    annotation = other.annotations.create!(annotation_text: "Elsewhere", x_coord: 0.1, y_coord: 0.1)

    delete admin_artifact_file_annotation_path(@file, annotation)

    assert_response :not_found
    assert Annotation.exists?(annotation.id)
  end
end
