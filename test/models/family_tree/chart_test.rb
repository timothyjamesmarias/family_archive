require "test_helper"

class FamilyTree::ChartTest < ActiveSupport::TestCase
  setup do
    @mutations = FamilyTree::Mutations.new
    @john = Individual.create!(given_name: "John", surname: "Marias", sex: "M", is_tree_root: true)
    @mutations.add_spouse(person_id: @john.id, spouse_data: { givenName: "Mary", sex: "F" })
    @mutations.add_child(parent_id: @john.id, child_data: { givenName: "Peter", sex: "M" })
    @mutations.add_sibling(person_id: person("Peter").id, sibling_data: { givenName: "Anna", sex: "F" })
    # Mother first, so the father-left rule has to do some work.
    @mutations.add_parent(child_id: @john.id, role: "MOTHER", parent_data: { givenName: "Grandma", sex: "F" })
    @mutations.add_parent(child_id: @john.id, role: "FATHER", parent_data: { givenName: "Senior", sex: "M" })
  end

  def person(name) = Individual.find_by!(given_name: name)

  def card(chart, name)
    chart.cards.find { |card| card.person[:givenName] == name } ||
      flunk("#{name} is not on the chart: #{chart.cards.map { |c| c.person[:givenName] }}")
  end

  def names(chart) = chart.cards.map { |card| card.person[:givenName] }.sort

  test "the initial chart shows the roots with spouses and parents, one generation per row" do
    chart = FamilyTree::Chart.new

    assert_equal %w[Grandma John Mary Senior], names(chart)
    assert_equal 0, card(chart, "Senior").position.generation
    assert_equal 1, card(chart, "John").position.generation
    assert_equal 2, chart.layout.height
  end

  test "the father is drawn left of the mother and a child under them" do
    chart = FamilyTree::Chart.new

    assert_operator card(chart, "Senior").position.x, :<, card(chart, "Grandma").position.x
    assert_in_delta (card(chart, "Senior").position.x + card(chart, "Grandma").position.x) / 2,
      card(chart, "John").position.x
  end

  test "expanding down adds the children in birth order" do
    chart = FamilyTree::Chart.new(down: [ @john.id ])

    assert_equal %w[Anna Grandma John Mary Peter Senior], names(chart)
    assert_equal 2, card(chart, "Peter").position.generation
    assert_operator card(chart, "Peter").position.x, :<, card(chart, "Anna").position.x
  end

  test "expanding up adds the grandparents" do
    @mutations.add_parent(child_id: person("Senior").id, role: "FATHER", parent_data: { givenName: "Great", sex: "M" })

    chart = FamilyTree::Chart.new(up: [ person("Senior").id ])

    assert_equal 0, card(chart, "Great").position.generation
    assert_equal 1, card(chart, "Senior").position.generation
    assert_equal 2, card(chart, "John").position.generation
  end

  test "cards flag the directions that still have relatives to load" do
    @mutations.add_parent(child_id: person("Senior").id, role: "FATHER", parent_data: { givenName: "Great", sex: "M" })

    chart = FamilyTree::Chart.new
    assert card(chart, "John").expands_down?, "John's children are not loaded"
    assert card(chart, "Senior").expands_up?, "Senior's father is not loaded"
    assert_not card(chart, "John").expands_up?, "John's parents are on the chart"
    assert_not card(chart, "Mary").expands_down?, "Mary has no children"

    expanded = FamilyTree::Chart.new(up: [ person("Senior").id ], down: [ @john.id ])
    assert_not card(expanded, "John").expands_down?
    assert_not card(expanded, "Senior").expands_up?
  end

  test "expansions of people who are not on the chart are ignored" do
    stranger = Individual.create!(given_name: "Stranger")

    assert_equal names(FamilyTree::Chart.new), names(FamilyTree::Chart.new(up: [ stranger.id, 0 ]))
  end
end
