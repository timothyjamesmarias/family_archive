require "test_helper"

module Ui
  class ButtonComponentTest < ViewComponent::TestCase
    test "renders a button by default" do
      render_inline(ButtonComponent.new) { "Upload artifact" }

      assert_selector "button.btn-primary[type='button']", text: "Upload artifact"
    end

    test "renders a link when given href" do
      render_inline(ButtonComponent.new(variant: :secondary, href: "/artifacts")) { "Browse" }

      assert_selector "a.btn-secondary[href='/artifacts']", text: "Browse"
      assert_no_selector "button"
    end

    test "applies size and merges extra classes" do
      render_inline(ButtonComponent.new(size: :sm, class: "w-full")) { "Save" }

      assert_selector "button.btn-primary.btn-sm.w-full"
    end

    test "passes through disabled and submit type" do
      render_inline(ButtonComponent.new(type: "submit", disabled: true)) { "Publish" }

      assert_selector "button[type='submit'][disabled]"
    end

    test "rejects unknown variants" do
      assert_raises(KeyError) { ButtonComponent.new(variant: :tertiary) }
    end
  end
end
