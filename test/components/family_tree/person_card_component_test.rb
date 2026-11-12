require "test_helper"

module FamilyTree
  class PersonCardComponentTest < ViewComponent::TestCase
    def card(person, x: 0, generation: 0, **flags)
      Chart::Card.new(
        person: { id: 7, relationships: {} }.merge(person),
        position: Layout::Position.new(x:, generation:),
        expands_up: false, expands_down: false, **flags
      )
    end

    test "places the card in pixels from its slot and row" do
      render_inline(PersonCardComponent.new(card: card({ givenName: "Anna", surname: "Vogt" }, x: 1.5, generation: 2)))

      assert_selector "#person-7.tree-card[style='left: 373px; top: 360px']"
      assert_selector ".tree-card-name", text: "Anna Vogt"
    end

    test "shows years only, in the design's three forms" do
      render_inline(PersonCardComponent.new(card: card({ birthDate: "12 JUN 1849", deathDate: "ABT 1921" })))
      assert_selector ".tree-card-dates", text: "1849 – 1921"

      render_inline(PersonCardComponent.new(card: card({ birthDate: "1918" })))
      assert_selector ".tree-card-dates", text: "b. 1918"

      render_inline(PersonCardComponent.new(card: card({ deathDate: "1921" })))
      assert_selector ".tree-card-dates", text: "d. 1921"
    end

    test "a person with no name is marked as unnamed" do
      render_inline(PersonCardComponent.new(card: card({})))

      assert_selector ".tree-card-name.tree-card-unnamed", text: "Unnamed"
    end

    test "renders expand links only where given" do
      render_inline(PersonCardComponent.new(card: card({ givenName: "Peter" }), down_href: "/family-tree/chart?down[]=7"))

      assert_selector "a.tree-expand-down[href='/family-tree/chart?down[]=7']", text: "+ ↓"
      assert_no_selector "a.tree-expand-up"
    end

    test "passes extra attributes through to the card" do
      render_inline(PersonCardComponent.new(card: card({}), data: { tree_zoom_target: "root" }))

      assert_selector ".tree-card[data-tree-zoom-target='root']"
    end
  end
end
