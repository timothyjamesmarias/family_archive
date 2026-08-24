require "test_helper"

module Ui
  class TabsComponentTest < ViewComponent::TestCase
    test "marks the active tab and shows counts" do
      render_inline(TabsComponent.new) do |tabs|
        tabs.with_tab(label: "Scan", href: "#scan", active: true)
        tabs.with_tab(label: "Annotations", href: "#annotations", count: 4)
      end

      assert_selector "nav a.tab.tab-active[aria-current='page']", text: "Scan"
      assert_selector "nav a.tab:not(.tab-active)", text: /Annotations/
      assert_selector "a .font-mono", text: "4"
    end
  end
end
