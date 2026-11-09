require "test_helper"

class Admin::TabsComponentTest < ViewComponent::TestCase
  test "the tab whose href is current is marked as the page" do
    render_inline(Admin::TabsComponent.new(current: "/b")) do |tabs|
      tabs.with_tab(label: "A", href: "/a")
      tabs.with_tab(label: "B", href: "/b")
    end

    assert_selector "a[aria-current=page]", count: 1, text: "B"
  end
end
