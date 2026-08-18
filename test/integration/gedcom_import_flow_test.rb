require "test_helper"

class GedcomImportFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "uploading a .ged enqueues the import and the job populates the tree" do
    sign_in create_admin

    assert_enqueued_with(job: GedcomImportJob) do
      post admin_gedcom_import_path, params: {
        file: fixture_file_upload("family_tree.ged", "text/plain")
      }
    end
    assert_redirected_to admin_gedcom_import_path

    perform_enqueued_jobs
    assert_equal 93, Individual.count
    assert_equal 30, Family.count
  end

  test "the stashed upload is removed after the job runs" do
    sign_in create_admin
    post admin_gedcom_import_path, params: {
      file: fixture_file_upload("family_tree.ged", "text/plain")
    }

    stashed_path = enqueued_jobs.last[:args].first
    assert File.exist?(stashed_path)

    perform_enqueued_jobs
    assert_not File.exist?(stashed_path)
  end

  test "non-ged files are rejected" do
    sign_in create_admin

    post admin_gedcom_import_path, params: {
      file: fixture_file_upload("artifact.png", "image/png")
    }

    assert_redirected_to admin_gedcom_import_path
    assert_match(/must be a .ged/, flash[:alert])
    assert_equal 0, Individual.count
  end

  test "the import screen requires an admin" do
    sign_in User.create!(email: "m@example.com", password: "password123", name: "Member")

    get admin_gedcom_import_path
    assert_redirected_to root_path
  end
end
