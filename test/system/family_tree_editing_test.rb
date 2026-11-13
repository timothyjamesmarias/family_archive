require "application_system_test_case"

# Edit mode in the browser: a card's menu loads a form into the dialog, a
# rejected submission stays in the dialog, a save refreshes the chart in place.
class FamilyTreeEditingTest < ApplicationSystemTestCase
  setup do
    mutations = FamilyTree::Mutations.new
    @john = Individual.create!(given_name: "John", surname: "Marias", sex: "M", is_tree_root: true)
    mutations.add_spouse(person_id: @john.id, spouse_data: { givenName: "Mary", surname: "Smith", sex: "F" })
    sign_in_as email: "editor@example.com"
  end

  test "adding a child from a card's menu shows the child on the chart and keeps the view" do
    visit family_tree_path(edit: 1)
    assert_selector ".tree-card", count: 2
    find("button[aria-label='Zoom out']").click
    assert_selector "[data-tree-zoom-target='level']", text: "80%"

    within("#person-#{@john.id}") { find("summary").click }
    within("#person-#{@john.id}") { click_on "Add child" }

    within("dialog[open]") do
      assert_text "Add a child of John Marias"
      fill_in "Given name", with: "Peter"
      fill_in "Surname", with: "Marias"
      click_on "Add"
    end

    assert_selector ".tree-card-name", text: "Peter Marias"
    assert_no_selector "dialog[open]"
    assert_selector ".toast-stack .message", text: "Child added for John Marias"
    assert_current_path(/edit=1/)
    assert_selector "[data-tree-zoom-target='level']", text: "80%"
  end

  test "editing a person updates their card in place" do
    visit family_tree_path(edit: 1)

    within("#person-#{@john.id}") { find("summary").click }
    within("#person-#{@john.id}") { click_on "Edit" }
    within("dialog[open]") do
      fill_in "Given name", with: "Johann"
      fill_in "Birth date", with: "1849"
      click_on "Save"
    end

    assert_selector "#person-#{@john.id} .tree-card-name", text: "Johann Marias"
    assert_selector "#person-#{@john.id} .tree-card-dates", text: "b. 1849"
  end

  test "a refused change stays in the dialog with its reason" do
    visit family_tree_path(edit: 1)

    within("#person-#{@john.id}") { find("summary").click }
    within("#person-#{@john.id}") { click_on "Add sibling" }
    within("dialog[open]") do
      fill_in "Given name", with: "Nobody"
      click_on "Add"
      assert_selector ".message-error", text: /no parent family/
    end

    assert_selector "dialog[open]"
    click_on "Cancel"
    assert_no_selector "dialog[open]"
  end
end
