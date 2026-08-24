require "test_helper"

module Ui
  class ChipComponentsTest < ViewComponent::TestCase
    test "written records take terracotta" do
      render_inline(TypeChipComponent.new(artifact_type: ArtifactType.fetch("LETTER")))

      assert_selector "span.chip.chip-terracotta", text: "Letter"
    end

    test "photos take sage and media takes dusty" do
      render_inline(TypeChipComponent.new(artifact_type: ArtifactType.fetch("PHOTO")))
      assert_selector "span.chip.chip-sage", text: "Photo"

      render_inline(TypeChipComponent.new(artifact_type: ArtifactType.fetch("AUDIO")))
      assert_selector "span.chip.chip-dusty", text: "Audio Recording"
    end

    test "small size for card contexts" do
      render_inline(TypeChipComponent.new(artifact_type: ArtifactType.fetch("LEDGER"), size: :sm))

      assert_selector "span.chip.chip-sm"
    end

    test "status chip is neutral by default and can demand attention" do
      render_inline(StatusChipComponent.new) { "Transcribed" }
      assert_selector "span.chip-status", text: "Transcribed"

      render_inline(StatusChipComponent.new(tone: :attention)) { "Needs transcription" }
      assert_selector "span.chip-status.chip-status-attention"
    end
  end
end
