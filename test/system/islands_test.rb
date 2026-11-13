require "application_system_test_case"

# Regression guard for the asset pipeline: if Vite, Tailwind or the public
# bundle breaks, these fail. The tree is an ordinary Turbo page now.
class IslandsTest < ApplicationSystemTestCase
  test "the family tree renders its cards and edges" do
    Individual.create!(given_name: "Root", surname: "Marias", is_tree_root: true)

    visit family_tree_path

    assert_selector ".tree-card-name", text: "Root Marias"
    assert_selector "svg.tree-edges", visible: :all
  end

  test "Turbo navigates into and out of the tree page" do
    Individual.create!(given_name: "Root", surname: "Marias", is_tree_root: true)
    visit root_path
    page.execute_script("window.marker = 1")

    within("nav[aria-label='Primary']", match: :first) { click_on "Family Tree" }
    assert_selector ".tree-card-name", text: "Root Marias"
    assert_equal 1, page.evaluate_script("window.marker"), "the tree page should be a Turbo visit, not a full load"

    within("nav[aria-label='Primary']", match: :first) { click_on "Articles" }
    assert_selector "h1", text: "Articles"
    assert_equal 1, page.evaluate_script("window.marker")
  end
end
