module Ui
  # Neutral status chips — the application talking, so Inter rather than
  # mono. :attention marks work the archive still owes (e.g. "Needs
  # transcription").
  class StatusChipComponent < ApplicationComponent
    TONE_CLASSES = { neutral: nil, attention: "chip-status-attention" }.freeze
    SIZE_CLASSES = { md: nil, sm: "chip-status-sm" }.freeze

    def initialize(tone: :neutral, size: :md)
      @tone = tone
      @size = size
    end

    def call
      tag.span content, class: class_names("chip-status", TONE_CLASSES.fetch(@tone), SIZE_CLASSES.fetch(@size))
    end
  end
end
