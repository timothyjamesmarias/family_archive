require "test_helper"

class GedcomImporterTest < ActiveSupport::TestCase
  FIXTURE = Rails.root.join("test/fixtures/files/family_tree.ged").to_s

  def import
    Gedcom::Importer.new.import_file(FIXTURE)
  end

  test "imports every individual, family, and event from the file" do
    result = import

    assert result[:success]
    assert_equal 93, result[:individuals_imported]
    assert_equal 30, result[:families_imported]
    assert_equal Individual.count, 93
    assert_equal Family.count, 30
    assert_equal IndividualEvent.count, result[:events_imported]
  end

  test "parses names, sex, events, and family roles" do
    import

    alexandra = Individual.find_by!(gedcom_id: "@I1@")
    assert_equal "Alexandra", alexandra.given_name
    assert_equal "Marias", alexandra.surname
    assert_equal "F", alexandra.sex
    birth = alexandra.events.find_by!(event_type: "BIRTH")
    assert_equal "11 FEB 1991", birth.date_string
    assert_equal Date.new(1991, 2, 11), birth.date_parsed.to_date

    family = Family.find_by!(gedcom_id: "@F1@")
    roles = family.members.map(&:role).tally
    assert_equal 1, roles["FATHER"]
    assert_equal 1, roles["MOTHER"]
    assert_equal [ 0, 1, 2 ], family.members.children.order(:child_order).map(&:child_order)
  end

  test "stores the raw record tree for round-tripping" do
    import

    raw = Individual.find_by!(gedcom_id: "@I1@").gedcom_raw_data
    record = raw["children"].sole
    assert_equal "INDI", record["tag"]
    assert_equal "@I1@", record["pointer"]
    assert(record["children"].any? { |child| child["tag"] == "NAME" })
  end

  test "re-import is idempotent" do
    first = import
    second = import

    assert_equal first.except(:warnings, :errors), second.except(:warnings, :errors)
    assert_equal 93, Individual.count
    assert_equal first[:events_imported], IndividualEvent.count
    assert_equal 5, Family.find_by!(gedcom_id: "@F1@").members.count
  end

  test "re-import preserves events and members an archivist added by hand" do
    import
    alexandra = Individual.find_by!(gedcom_id: "@I1@")
    alexandra.events.create!(event_type: "OCCUPATION", description: "Archivist")
    manual = Individual.create!(given_name: "Handmade")
    family = Family.find_by!(gedcom_id: "@F1@")
    FamilyMember.create!(family_id: family.id, individual_id: manual.id, role: "CHILD",
      child_order: 99)

    import

    assert alexandra.events.exists?(event_type: "OCCUPATION")
    assert_equal 1, alexandra.events.where(event_type: "BIRTH").count
    assert FamilyMember.exists?(family_id: family.id, individual_id: manual.id)
  end

  test "re-import updates a soft-deleted individual without resurrecting them" do
    import
    Individual.find_by!(gedcom_id: "@I1@").destroy

    result = import

    assert result[:success]
    assert_nil Individual.find_by(gedcom_id: "@I1@")
    assert Individual.with_deleted.find_by!(gedcom_id: "@I1@").deleted?
  end

  test "rejects a file that is not GEDCOM" do
    Tempfile.create([ "not-gedcom", ".ged" ]) do |file|
      file.write("this is just text")
      file.flush

      error = assert_raises(InvalidArgumentError) do
        Gedcom::Importer.new.import_file(file.path)
      end
      assert_equal "file", error.field
    end
  end
end
