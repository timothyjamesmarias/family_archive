require "test_helper"

module Ui
  class MessageComponentTest < ViewComponent::TestCase
    test "levels carry their default mono labels" do
      render_inline(MessageComponent.new(level: :success)) { "Transcription published." }
      assert_selector ".message.message-success .message-label", text: "Saved"
      assert_selector ".message-body", text: "Transcription published."

      render_inline(MessageComponent.new(level: :warning)) { "Two people unidentified." }
      assert_selector ".message-warning .message-label", text: "Check"
    end

    test "label can be overridden and attributes pass through" do
      render_inline(
        MessageComponent.new(level: :error, label: "Failed", data: { testid: "flash-alert" })
      ) { "Upload failed." }

      assert_selector ".message-error[data-testid='flash-alert'] .message-label", text: "Failed"
    end

    test "rejects unknown levels" do
      assert_raises(KeyError) { MessageComponent.new(level: :fatal) }
    end
  end
end
