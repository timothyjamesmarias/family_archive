module Ui
  # The five link roles from the foundations: verdigris acts, terracotta
  # names people and places, citations are dotted, external links carry the
  # mono arrow, footnotes are superscript mono brackets. Covers links the
  # application generates; authored article HTML gets these via prose CSS.
  class LinkComponent < ApplicationComponent
    ROLE_CLASSES = {
      action: "link",
      person: "link-person",
      place: "link-person",
      citation: "link-citation",
      external: "link",
      footnote: "link-footnote"
    }.freeze

    def initialize(href:, role: :action, **attributes)
      @href = href
      @role = role
      @attributes = attributes
      @attributes[:class] = class_names(ROLE_CLASSES.fetch(role), attributes[:class])
    end

    def call
      link_to @href, **@attributes do
        safe_join([ body ].compact)
      end
    end

    private

    def body
      return content unless @role == :external

      safe_join([ content, tag.span(" ↗", class: "font-mono text-[11px] text-taupe-600 dark:text-ink-200") ])
    end
  end
end
