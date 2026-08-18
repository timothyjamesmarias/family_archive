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

  test "other public pages do not load the family-tree bundle" do
    visit root_path

    assert_no_selector "script[src*='family_tree']", visible: false
  end
end
