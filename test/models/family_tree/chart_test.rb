require "test_helper"

class FamilyTree::ChartTest < ActiveSupport::TestCase
  setup do
    @mutations = FamilyTree::Mutations.new
    @john = Individual.create!(given_name: "John", surname: "Marias", sex: "M", is_tree_root: true)
    @mutations.add_spouse(person_id: @john.id, spouse_data: { givenName: "Mary", sex: "F" })
    @mutations.add_child(parent_id: @john.id, child_data: { givenName: "Peter", sex: "M" })
    @mutations.add_sibling(person_id: person("Peter").id, sibling_data: { givenName: "Anna", sex: "F" })
    @mutations.add_child(parent_id: person("Peter").id, child_data: { givenName: "Junior", sex: "M" })
    # Mother first, so the father-left rule has to do some work.
    @mutations.add_parent(child_id: @john.id, role: "MOTHER", parent_data: { givenName: "Grandma", sex: "F" })
    @mutations.add_parent(child_id: @john.id, role: "FATHER", parent_data: { givenName: "Senior", sex: "M" })
    @mutations.add_parent(child_id: person("Senior").id, role: "FATHER", parent_data: { givenName: "Great", sex: "M" })
  end

  def person(name) = Individual.find_by!(given_name: name)

  def card(chart, name)
    chart.cards.find { |card| card.person[:givenName] == name } ||
      flunk("#{name} is not on the chart: #{chart.cards.map { |c| c.person[:givenName] }}")
  end

  def names(chart) = chart.cards.map { |card| card.person[:givenName] }.sort

  test "the chart shows one generation each way from the roots, with spouses, one generation per row" do
    chart = FamilyTree::Chart.new

    assert_equal %w[Anna Grandma John Mary Peter Senior], names(chart)
    assert_equal 0, card(chart, "Senior").position.generation
    assert_equal 1, card(chart, "John").position.generation
    assert_equal 2, card(chart, "Peter").position.generation
    assert_equal 3, chart.layout.height
    assert_equal 6, chart.shown
    assert_equal 8, chart.total
  end

  test "the father is drawn left of the mother and a child under them" do
    chart = FamilyTree::Chart.new

    assert_operator card(chart, "Senior").position.x, :<, card(chart, "Grandma").position.x
    assert_in_delta (card(chart, "Senior").position.x + card(chart, "Grandma").position.x) / 2,
      card(chart, "John").position.x
  end

  test "children come in birth order" do
    chart = FamilyTree::Chart.new

    assert_operator card(chart, "Peter").position.x, :<, card(chart, "Anna").position.x
  end

  test "a deeper chart reaches further both ways" do
    chart = FamilyTree::Chart.new(depth: 2)

    assert_equal %w[Anna Grandma Great John Junior Mary Peter Senior], names(chart)
    assert_equal 0, card(chart, "Great").position.generation
    assert_equal 4, card(chart, "Junior").position.generation
  end

  test "expanding down adds the children of that person" do
    chart = FamilyTree::Chart.new(down: [ person("Peter").id ])

    assert_equal 3, card(chart, "Junior").position.generation
    assert_not_includes names(chart), "Great"
  end

  test "expanding up adds the parents of that person" do
    chart = FamilyTree::Chart.new(up: [ person("Senior").id ])

    assert_equal 0, card(chart, "Great").position.generation
    assert_equal 1, card(chart, "Senior").position.generation
    assert_not_includes names(chart), "Junior"
  end

  test "cards flag the directions that still have relatives to load" do
    chart = FamilyTree::Chart.new
    assert card(chart, "Peter").expands_down?, "Peter's child is not loaded"
    assert card(chart, "Senior").expands_up?, "Senior's father is not loaded"
    assert_not card(chart, "John").expands_up?, "John's parents are on the chart"
    assert_not card(chart, "John").expands_down?, "John's children are on the chart"
    assert_not card(chart, "Mary").expands_down?, "Mary has no children"

    expanded = FamilyTree::Chart.new(up: [ person("Senior").id ], down: [ person("Peter").id ])
    assert_not card(expanded, "Peter").expands_down?
    assert_not card(expanded, "Senior").expands_up?
  end

  test "expansions of people who are not on the chart are ignored" do
    stranger = Individual.create!(given_name: "Stranger")

    assert_equal names(FamilyTree::Chart.new), names(FamilyTree::Chart.new(up: [ stranger.id, 0 ]))
  end

  test "birth order beats insertion order and id order" do
    FamilyMember.children.find_by!(individual_id: person("Anna").id).update!(child_order: -1)

    chart = FamilyTree::Chart.new(down: [ @john.id ])

    assert_operator card(chart, "Anna").position.x, :<, card(chart, "Peter").position.x
  end

  test "an expansion waits for the one that brings its person, whatever the URL order" do
    @mutations.add_parent(child_id: person("Senior").id, role: "FATHER", parent_data: { givenName: "Great", sex: "M" })
    @mutations.add_parent(child_id: person("Great").id, role: "FATHER", parent_data: { givenName: "Elder", sex: "M" })

    chart = FamilyTree::Chart.new(up: [ person("Great").id, person("Senior").id ])

    assert_equal 0, card(chart, "Elder").position.generation
    assert_equal names(chart), names(FamilyTree::Chart.new(up: [ person("Senior").id, person("Great").id, person("Great").id ]))
  end

  test "units come in family id order" do
    @mutations.add_spouse(person_id: person("Peter").id, spouse_data: { givenName: "Wife", sex: "F" })

    chart = FamilyTree::Chart.new(down: [ @john.id ])

    assert_equal chart.units.map(&:id), chart.units.map(&:id).sort
  end

  test "expanding up shows the siblings and the parents, but not a sibling's childless marriage" do
    @mutations.add_parent(child_id: person("Senior").id, role: "FATHER", parent_data: { givenName: "Great", sex: "M" })
    @mutations.add_sibling(person_id: person("Senior").id, sibling_data: { givenName: "Uncle", sex: "M" })
    @mutations.add_spouse(person_id: person("Uncle").id, spouse_data: { givenName: "Aunt", sex: "F" })
    @mutations.add_sibling(person_id: person("Senior").id, sibling_data: { givenName: "Father", sex: "M" })
    @mutations.add_spouse(person_id: person("Father").id, spouse_data: { givenName: "Mother", sex: "F" })
    @mutations.add_child(parent_id: person("Father").id, parent_family_id: Family.order(:id).last.id,
      child_data: { givenName: "Cousin", sex: "F" })

    chart = FamilyTree::Chart.new(up: [ person("Senior").id ])

    assert_includes names(chart), "Uncle"
    assert_includes names(chart), "Father"
    assert_not_includes names(chart), "Aunt", "an in-law floats beside the sibling with nothing attaching them"
    assert_not_includes names(chart), "Cousin", "siblings' descendants are a down-expansion away"
    # A sibling's children are never in an up-response, so neither is the
    # spouse; the expand tab says there is more below.
    assert_not_includes names(chart), "Mother"
    assert card(chart, "Father").expands_down?
  end
end
