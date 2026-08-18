require "test_helper"

class ArtifactUploadsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup { sign_in create_admin }

  def upload_artifact
    post admin_artifacts_path, params: {
      files: [ fixture_file_upload("artifact.png", "image/png") ],
      artifact: { artifact_type: "PHOTO", title: "Family portrait", original_date_string: "1943" }
    }
    Artifact.find_by!(title: "Family portrait")
  end

  test "uploading creates the artifact with an attached file" do
    artifact = upload_artifact

    assert_redirected_to admin_artifact_path(artifact)
    primary = artifact.primary_file
    assert_equal 1, primary.file_sequence
    assert primary.file.attached?
    assert_equal "image/png", primary.file.blob.content_type
    assert primary.image?
  end

  test "the public collection renders the uploaded image" do
    upload_artifact

    get "/photos"
    assert_match "Family portrait", response.body
    assert_match "rails/active_storage", response.body
  end

  test "added files continue the sequence and can be removed" do
    artifact = upload_artifact

    post add_files_admin_artifact_path(artifact), params: {
      files: [ fixture_file_upload("artifact.png", "image/png") ]
    }
    assert_equal [ 1, 2 ], artifact.reload.files.map(&:file_sequence)

    delete file_admin_artifact_path(artifact, artifact.files.last.id)
    assert_equal [ 1 ], artifact.reload.files.map(&:file_sequence)
  end

  test "the only file cannot be removed" do
    artifact = upload_artifact

    delete file_admin_artifact_path(artifact, artifact.primary_file.id)

    assert_equal 1, artifact.reload.files.count
    assert_match(/Cannot delete the only file/, flash[:alert])
  end

  test "destroying the artifact purges its blobs" do
    artifact = upload_artifact
    blob = artifact.primary_file.file.blob

    delete admin_artifact_path(artifact)
    # Only the purge jobs: the also-enqueued variant transform needs libvips,
    # which the test environment does not require.
    perform_enqueued_jobs(only: ActiveStorage::PurgeJob)

    assert_not Artifact.exists?(artifact.id)
    assert_not ActiveStorage::Blob.exists?(blob.id)
  end

  test "disallowed extensions are rejected" do
    post admin_artifacts_path, params: {
      files: [ fixture_file_upload("script.sh", "application/x-sh") ],
      artifact: { artifact_type: "PHOTO", title: "Nope" }
    }

    assert_response :unprocessable_entity
    assert_nil Artifact.find_by(title: "Nope")
  end
end
