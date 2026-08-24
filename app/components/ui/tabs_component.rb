module Ui
  # A row of link tabs over a hairline; the active tab carries the inset
  # verdigris underline. Counts render as mono suffixes.
  class TabsComponent < ApplicationComponent
    class TabComponent < ApplicationComponent
      def initialize(label:, href:, active: false, count: nil)
        @label = label
        @href = href
        @active = active
        @count = count
      end

      def call
        link_to @href, class: class_names("tab", "tab-active": @active), "aria-current": (@active ? "page" : nil) do
          safe_join([
            @label,
            (tag.span(@count, class: "font-mono text-xs text-taupe-600 dark:text-ink-200") if @count)
          ].compact, " ")
        end
      end
    end

    renders_many :tabs, TabComponent

    def call
      tag.nav(safe_join(tabs), class: "flex flex-wrap border-b border-taupe-200 dark:border-ink-500", aria: { label: "Tabs" })
    end
  end
end
