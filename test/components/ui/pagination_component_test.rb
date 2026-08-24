require "test_helper"

module Ui
  class PaginationComponentTest < ViewComponent::TestCase
    def pages(current:, total:, per_page: 24)
      Pagination.new(records: [], current_page: current, per_page: per_page, total: total)
    end

    test "renders nothing for a single page" do
      render_inline(PaginationComponent.new(page: pages(current: 1, total: 10), base_url: "/photos"))

      assert_no_selector "nav"
    end

    test "windows around the current page with ellipses" do
      render_inline(PaginationComponent.new(page: pages(current: 9, total: 18 * 24), base_url: "/photos"))

      assert_selector ".pager-cell-current", text: "9"
      assert_selector "a.pager-cell", text: "1"
      assert_selector "a.pager-cell", text: "18"
      assert_selector "a.pager-cell[href='/photos?page=8']", text: "8"
      assert_no_selector "a.pager-cell", text: "4"
      assert_selector "nav span", text: "…", count: 2
    end

    test "prev disabled on the first page, next disabled on the last" do
      render_inline(PaginationComponent.new(page: pages(current: 1, total: 60), base_url: "/photos"))
      assert_selector "span.pager-cell-disabled", text: "Prev"
      assert_selector "a.pager-cell[href='/photos?page=2']", text: "Next"

      render_inline(PaginationComponent.new(page: pages(current: 3, total: 60), base_url: "/photos"))
      assert_selector "span.pager-cell-disabled", text: "Next"
    end

    test "optional count label pluralizes the noun" do
      render_inline(PaginationComponent.new(page: pages(current: 1, total: 214), base_url: "/photos", noun: "artifact"))

      assert_selector ".meta", text: "214 artifacts"
    end
  end
end
