require "application_system_test_case"

# Regression guard for the asset pipeline: if Vite, Tailwind, or the
# island mount breaks, these fail.
class IslandsTest < ApplicationSystemTestCase
  test "the family-tree island mounts and renders its canvas" do
    Individual.create!(given_name: "Root", surname: "Marias", is_tree_root: true)

    visit family_tree_path

    assert_selector "#family-tree-root"
    assert_selector "tree-canvas svg", visible: :all
  end

  test "Turbo links into and out of the tree page are full loads" do
    Individual.create!(given_name: "Root", surname: "Marias", is_tree_root: true)
    visit root_path

    within("nav[aria-label='Primary']", match: :first) { click_on "Family Tree" }
    assert_selector "tree-canvas svg", visible: :all

    within("nav[aria-label='Primary']", match: :first) { click_on "Articles" }
    assert_selector "h1", text: "Articles"
    assert_no_selector "script[src*='family_tree']", visible: false

    go_back
    assert_selector "tree-canvas svg", visible: :all
  end

  test "the Family Tree link on the tree page reloads it with the island mounted" do
    Individual.create!(given_name: "Root", surname: "Marias", is_tree_root: true)
    visit family_tree_path
    assert_selector "tree-canvas svg", visible: :all
    page.execute_script("window.marker = 1")

    within("nav[aria-label='Primary']", match: :first) { click_on "Family Tree" }

    # Same tracked tags, so only the visit-control meta forces this reload.
    page.document.synchronize { raise Capybara::ExpectationNotMet if page.evaluate_script("window.marker") }
    assert_selector "tree-canvas svg", visible: :all
  end

  test "other public pages do not load the family-tree bundle" do
    visit root_path

    assert_no_selector "script[src*='family_tree']", visible: false
  end
end
