require "test_helper"

module Ui
  class LinkComponentTest < ViewComponent::TestCase
    test "action link by default" do
      render_inline(LinkComponent.new(href: "/articles")) { "the crossing, retold" }

      assert_selector "a.link[href='/articles']", text: "the crossing, retold"
    end

    test "people and places share the terracotta role" do
      render_inline(LinkComponent.new(href: "/people/anna", role: :person)) { "Anna Marias" }
      assert_selector "a.link-person"

      render_inline(LinkComponent.new(href: "/places/bremen", role: :place)) { "Bremen" }
      assert_selector "a.link-person"
    end

    test "external links carry the mono arrow" do
      render_inline(LinkComponent.new(href: "https://example.org", role: :external)) { "county archive" }

      assert_selector "a.link", text: /county archive/
      assert_selector "a .font-mono", text: "↗"
    end

    test "citation and footnote roles" do
      render_inline(LinkComponent.new(href: "#src", role: :citation)) { "the 1931 letter" }
      assert_selector "a.link-citation"

      render_inline(LinkComponent.new(href: "#note-3", role: :footnote)) { "[3]" }
      assert_selector "a.link-footnote", text: "[3]"
    end
  end
end
