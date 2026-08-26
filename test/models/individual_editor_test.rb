require "test_helper"

class IndividualEditorTest < ActiveSupport::TestCase
  setup { @editor = Individual::Editor.new }

  test "create builds birth and death events with places" do
    response = @editor.create_from_request(
      givenName: "Ada", surname: "Lovelace", sex: "F",
      birthDate: "10 DEC 1815", birthPlace: "London, England",
      deathDate: "27 NOV 1852", deathPlace: "London, England"
    )

    assert_equal "10 DEC 1815", response[:birthDate]
    assert_equal "London, England", response[:birthPlace]
    assert_equal 1, Place.count, "birth and death share one deduped place"
  end

  test "update clears an event when its fields are blanked" do
    created = @editor.create_from_request(givenName: "Ada", birthDate: "1815", birthPlace: "London")
    updated = @editor.update_from_request(created[:id], givenName: "Ada")

    assert_nil updated[:birthDate]
    assert_empty IndividualEvent.where(individual_id: created[:id])
  end

  test "cannot delete an individual with children" do
    parent = @editor.create_from_request(givenName: "John", sex: "M")
    FamilyTree::Mutations.new.add_child(parent_id: parent[:id],
      child_data: { givenName: "Peter" })

    result = @editor.can_delete(parent[:id])
    assert_not result[:valid]
    assert_match(/child/, result[:reason])
    assert_raises(ConflictError) { @editor.soft_delete(parent[:id]) }
  end

  test "soft delete hides the individual but keeps the row" do
    created = @editor.create_from_request(givenName: "Solo")

    assert @editor.soft_delete(created[:id])
    assert_nil Individual.find_by(id: created[:id])
    assert Individual.with_deleted.exists?(id: created[:id])
  end

  test "duplicate gedcom ids are refused" do
    @editor.create_from_request(gedcomId: "@I1@", givenName: "A")

    error = assert_raises(ConflictError) do
      @editor.create_from_request(gedcomId: "@I1@", givenName: "B")
    end
    assert_equal "gedcomId", error.field
  end
end
