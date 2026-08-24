require "test_helper"

module Ui
  class EmptyStateComponentTest < ViewComponent::TestCase
    test "title and body inside the dashed sheet" do
      render_inline(EmptyStateComponent.new(title: "Nothing catalogued here yet",
                                            body: "Check back as the archive grows."))

      assert_selector ".empty-state .font-serif", text: "Nothing catalogued here yet"
      assert_selector ".empty-state p", text: "Check back as the archive grows."
    end

    test "optional action slot" do
      render_inline(EmptyStateComponent.new(title: "Nothing here")) do |empty|
        empty.with_action { %(<button class="btn-primary">Upload the first item</button>).html_safe }
      end

      assert_selector ".empty-state button.btn-primary", text: "Upload the first item"
    end
  end
end
