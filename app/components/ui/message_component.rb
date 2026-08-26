module Ui
  # Flash and inline notices: a mono level label beside the message. The
  # default labels follow the foundations — Saved / Error / Check / Note.
  class MessageComponent < ApplicationComponent
    LEVELS = {
      success: { class: "message-success", label: "Saved" },
      error: { class: "message-error", label: "Error" },
      warning: { class: "message-warning", label: "Check" },
      info: { class: "message-info", label: "Note" }
    }.freeze

    def initialize(level:, label: nil, **attributes)
      @level = LEVELS.fetch(level)
      @label = label || @level.fetch(:label)
      @attributes = attributes
    end

    def call
      tag.div(**@attributes, class: class_names("message", @level.fetch(:class), @attributes[:class])) do
        safe_join([
          tag.span(@label, class: "message-label"),
          tag.p(content, class: "message-body m-0")
        ])
      end
    end
  end
end
