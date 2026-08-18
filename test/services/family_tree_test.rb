require "test_helper"

class FamilyTreeTest < ActiveSupport::TestCase
  setup do
    @mutations = FamilyTree::Mutations.new
    @john = Individual.create!(given_name: "John", surname: "Marias", sex: "M",
      is_tree_root: true)
  end

  test "add_spouse creates a family with both parents" do
    response = @mutations.add_spouse(
      person_id: @john.id,
      spouse_data: { givenName: "Mary", surname: "Smith", sex: "F" },
      marriage_data: { marriageDateString: "12 JUN 1950" }
    )

    names = response[:individuals].map { |i| i[:givenName] }
    assert_includes names, "John"
    assert_includes names, "Mary"
    family = response[:families].sole
    assert_equal 2, family[:parentIds].size

    assert_equal "12 JUN 1950", Family.sole.marriage_date_string
  end

  test "add_child reuses the given family and appends child order" do
    @mutations.add_child(parent_id: @john.id, child_data: { givenName: "Peter", surname: "Marias", sex: "M" })
    family_id = Family.sole.id
    @mutations.add_sibling(person_id: Individual.find_by(given_name: "Peter").id,
      sibling_data: { givenName: "Anna", surname: "Marias", sex: "F" })

    children = FamilyMember.children.where(family_id: family_id).order(:child_order)
    assert_equal [ 0, 1 ], children.map(&:child_order)
  end

  test "add_parent refuses a third parent" do
    child = @mutations.add_child(parent_id: @john.id,
      child_data: { givenName: "Peter", surname: "Marias", sex: "M" })
    peter_id = child[:individuals].find { |i| i[:givenName] == "Peter" }[:id]
    @mutations.add_parent(child_id: peter_id, role: "MOTHER",
      parent_data: { givenName: "Mary", sex: "F" })

    assert_raises(ConflictError) do
      @mutations.add_parent(child_id: peter_id, role: "MOTHER",
        parent_data: { givenName: "Another", sex: "F" })
    end
  end

  test "initial tree loads roots with spouses and boundary metadata" do
    @mutations.add_spouse(person_id: @john.id, spouse_data: { givenName: "Mary", sex: "F" })
    @mutations.add_child(parent_id: @john.id, child_data: { givenName: "Peter", surname: "Marias" })

    tree = FamilyTree::Builder.new.initial_tree
    john = tree[:individuals].find { |i| i[:givenName] == "John" }

    assert john[:relationships][:hasUnloadedDescendants],
      "children outside the response should flag unloaded descendants"
  end

  test "ancestor and sibling queries respect soft deletes" do
    @mutations.add_child(parent_id: @john.id, child_data: { givenName: "Peter", surname: "Marias" })
    peter = Individual.find_by(given_name: "Peter")
    @mutations.add_sibling(person_id: peter.id, sibling_data: { givenName: "Anna" })

    assert_equal %w[Anna], IndividualQueries.siblings(peter.id).map(&:given_name)
    assert_equal %w[Peter John], IndividualQueries.ancestors(peter.id, 5).map(&:given_name)

    Individual.find_by(given_name: "Anna").destroy
    assert_empty IndividualQueries.siblings(peter.id)
  end
end
