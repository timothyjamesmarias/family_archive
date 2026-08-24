module Ui
  # The artifact-type taxonomy chip. Tone comes from the type itself — the
  # colour is a redundant channel next to the text, never a caller choice.
  class TypeChipComponent < ApplicationComponent
    def initialize(artifact_type:, size: :md)
      @artifact_type = artifact_type
      @size = size
    end

    def call
      tag.span @artifact_type.display_name,
        class: class_names("chip", "chip-#{@artifact_type.chip_tone}", "chip-sm": @size == :sm)
    end
  end
end
