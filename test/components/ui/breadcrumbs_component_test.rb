require "test_helper"

module Ui
  class BreadcrumbsComponentTest < ViewComponent::TestCase
    test "links every crumb but the current page" do
      render_inline(BreadcrumbsComponent.new) do |trail|
        trail.with_crumb(label: "Archive", href: "/")
        trail.with_crumb(label: "Artifacts", href: "/artifacts")
        trail.with_crumb(label: "Photographs")
      end

      assert_selector "nav[aria-label='Breadcrumb']"
      assert_selector "nav a[href='/']", text: "Archive"
      assert_selector "nav a[href='/artifacts']", text: "Artifacts"
      assert_selector "nav span", text: "Photographs"
      assert_selector "nav span", text: "/", count: 2
    end
  end
end
