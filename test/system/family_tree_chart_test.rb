require "application_system_test_case"

# The server-rendered chart: cards and edges render, expanding swaps the frame
# in place, and the zoom controller drives the stage.
class FamilyTreeChartTest < ApplicationSystemTestCase
  setup do
    mutations = FamilyTree::Mutations.new
    john = Individual.create!(given_name: "John", surname: "Marias", sex: "M", is_tree_root: true)
    mutations.add_spouse(person_id: john.id, spouse_data: { givenName: "Mary", surname: "Smith", sex: "F" })
    mutations.add_child(parent_id: john.id, child_data: { givenName: "Peter", surname: "Marias", sex: "M" })
    peter = Individual.find_by!(given_name: "Peter")
    mutations.add_child(parent_id: peter.id, child_data: { givenName: "Junior", surname: "Marias", sex: "M" })
  end

  test "expanding a card loads its children into the frame without leaving the page" do
    visit family_tree_chart_path
    assert_selector ".tree-card", count: 3
    page.execute_script("window.marker = 1")

    find("a.tree-expand-down").click

    assert_selector ".tree-card-name", text: "Junior Marias"
    assert_equal 1, page.evaluate_script("window.marker"), "the frame swap turned into a full load"
    assert_current_path(/down%5B%5D=\d+/)
  end

  test "zoom buttons scale the stage" do
    visit family_tree_chart_path

    find("button[aria-label='Zoom out']").click

    assert_selector "[data-tree-zoom-target='level']", text: "80%"
    assert_equal "0.8", page.evaluate_script("document.querySelector('.tree-stage').style.zoom")
  end
end
