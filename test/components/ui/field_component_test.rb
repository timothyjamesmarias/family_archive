require "test_helper"

module Ui
  class FieldComponentTest < ViewComponent::TestCase
    test "wraps the control with a mono label" do
      render_inline(FieldComponent.new(label: "Title")) do
        %(<input type="text" class="field-input">).html_safe
      end

      assert_selector "label.field .field-label", text: "Title"
      assert_selector "label.field input.field-input"
      assert_no_selector ".field-invalid"
      assert_no_selector ".field-hint"
    end

    test "shows a hint" do
      render_inline(FieldComponent.new(label: "Date as written", hint: "Transcribe exactly as it appears.")) do
        %(<input type="text" class="field-input">).html_safe
      end

      assert_selector ".field-hint", text: "Transcribe exactly as it appears."
    end

    test "an error replaces the hint and marks the field invalid" do
      render_inline(FieldComponent.new(label: "Storage path", hint: "Where the scan lives.", error: "Required.")) do
        %(<input type="text" class="field-input">).html_safe
      end

      assert_selector "label.field.field-invalid .field-hint", text: "Required."
      assert_no_selector ".field-hint", text: "Where the scan lives."
    end
  end
end
