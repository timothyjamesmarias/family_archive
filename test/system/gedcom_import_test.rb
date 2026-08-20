require "application_system_test_case"

class GedcomImportTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test "importing a GEDCOM file through the Uppy dashboard" do
    sign_in_as email: "boss@example.com", admin: true

    visit admin_gedcom_import_path
    assert_selector ".uppy-Dashboard"

    attach_to_uppy Rails.root.join("test/fixtures/files/family_tree.ged")
    assert_selector ".uppy-Dashboard-Item"
    click_on "Import", exact: true

    assert_text "Import started"
    assert_equal 1, enqueued_jobs.count { |job| job[:job] == GedcomImportJob }

    # The result panel reads Rails.cache, a null store in test — the import's
    # effect is asserted on the data instead.
    perform_enqueued_jobs
    assert_equal 93, Individual.count
    assert_equal 30, Family.count
  end
end
