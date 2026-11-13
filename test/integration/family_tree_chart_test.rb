require "test_helper"

class FamilyTreeChartTest < ActionDispatch::IntegrationTest
  setup do
    mutations = FamilyTree::Mutations.new
    @john = Individual.create!(given_name: "John", surname: "Marias", sex: "M", is_tree_root: true)
    mutations.add_spouse(person_id: @john.id, spouse_data: { givenName: "Mary", surname: "Smith", sex: "F" })
    mutations.add_child(parent_id: @john.id, child_data: { givenName: "Peter", surname: "Marias", sex: "M" })
    @peter = Individual.find_by!(given_name: "Peter")
    mutations.add_child(parent_id: @peter.id, child_data: { givenName: "Junior", surname: "Marias", sex: "M" })
  end

  test "renders the loaded people as placed cards inside the chart frame" do
    get family_tree_path

    assert_response :success
    assert_select "turbo-frame#chart" do
      assert_select ".tree-card", count: 3
      assert_select "#person-#{@john.id}.tree-card[style*='left:'][style*='top:'] .tree-card-name", text: "John Marias"
      assert_select "svg.tree-edges path"
    end
  end

  test "a card with unloaded children links to the same URL plus its id" do
    get family_tree_path

    assert_select "#person-#{@peter.id} a.tree-expand-down[href=?]",
      family_tree_path(down: [ @peter.id ], anchor: "person-#{@peter.id}")
    assert_select "#person-#{@john.id} a.tree-expand-down", count: 0
  end

  test "expansions and depth come from the URL" do
    get family_tree_path(down: [ @peter.id ], depth: "2")

    assert_select ".tree-card-name", text: "Junior Marias"
    assert_select "a.tree-control-active[aria-current='true']", text: "2"
    assert_select "#person-#{@peter.id} a.tree-expand-down", count: 0
  end

  test "ignores ids that are not numbers" do
    get family_tree_path(up: [ "drop table", "" ], depth: "nope")

    assert_response :success
    assert_select ".tree-card", count: 3
  end
end
