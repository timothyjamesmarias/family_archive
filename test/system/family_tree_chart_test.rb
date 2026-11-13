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
    visit family_tree_path
    assert_selector ".tree-card", count: 3
    page.execute_script("window.marker = 1")

    find("a.tree-expand-down").click

    assert_selector ".tree-card-name", text: "Junior Marias"
    assert_equal 1, page.evaluate_script("window.marker"), "the frame swap turned into a full load"
    assert_current_path(/down%5B%5D=\d+/)
  end

  test "zoom buttons scale the stage and the view survives an expansion" do
    visit family_tree_path

    find("button[aria-label='Zoom out']").click
    assert_selector "[data-tree-zoom-target='level']", text: "80%"
    assert_match(/scale\(0\.8\)/, page.evaluate_script("document.querySelector('.tree-stage').style.transform"))

    find("a.tree-expand-down").click
    assert_selector ".tree-card-name", text: "Junior Marias"
    assert_selector "[data-tree-zoom-target='level']", text: "80%"
    assert_match(/scale\(0\.8\)/, page.evaluate_script("document.querySelector('.tree-stage').style.transform"))
  end

  # Two synthetic touch pointers move apart on the canvas: the stage should
  # scale up around them, and a single finger afterwards should still pan.
  test "a pinch zooms the stage and one finger pans it" do
    visit family_tree_path

    page.execute_script(<<~JS)
      const canvas = document.querySelector('.tree-canvas')
      const rect = canvas.getBoundingClientRect()
      const touch = (type, id, dx, dy) => canvas.dispatchEvent(new PointerEvent(type, {
        pointerId: id, pointerType: 'touch', button: 0, bubbles: true, isPrimary: id === 1,
        clientX: rect.left + 300 + dx, clientY: rect.top + 300 + dy }))
      touch('pointerdown', 1, -50, 0); touch('pointerdown', 2, 50, 0)
      touch('pointermove', 1, -100, 0); touch('pointermove', 2, 100, 0)
      touch('pointerup', 2, 100, 0)
      touch('pointermove', 1, -60, 40)
      touch('pointerup', 1, -60, 40)
    JS

    assert_selector "[data-tree-zoom-target='level']", text: "200%"
    transform = page.evaluate_script("document.querySelector('.tree-stage').style.transform")
    assert_match(/scale\(2\)/, transform)
    assert_no_match(/translate\(0px, 0px\)/, transform, "the single-finger move should have panned")
  end

  test "the wheel still zooms after a depth change swaps the canvas" do
    visit family_tree_path
    within(".tree-toolbar") { click_on "2" }
    assert_selector "a.tree-control-active", text: "2"

    page.execute_script(<<~JS)
      document.querySelector('.tree-canvas').dispatchEvent(
        new WheelEvent('wheel', { deltaY: -100, clientX: 50, clientY: 50, bubbles: true, cancelable: true }))
    JS

    assert_selector "[data-tree-zoom-target='level']", text: "122%"
  end
end
