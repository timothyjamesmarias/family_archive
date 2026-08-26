module Ui
  # The recessed mono breadcrumb bar. Every item but the last links; the
  # last names the current page.
  class BreadcrumbsComponent < ApplicationComponent
    class CrumbComponent < ApplicationComponent
      def initialize(label:, href: nil)
        @label = label
        @href = href
      end

      def call
        return tag.span(@label) unless @href

        link_to @label, @href, class: "text-verdigris-700 no-underline hover:underline dark:text-verdigris-300"
      end
    end

    renders_many :crumbs, CrumbComponent

    def call
      tag.nav(class: "bg-taupe-100 px-5 sm:px-8 py-3 flex flex-wrap gap-x-2.5 gap-y-1.5 items-center font-mono text-[11px] tracking-[0.06em] text-taupe-600 dark:bg-ink-600 dark:text-ink-200", aria: { label: "Breadcrumb" }) do
        safe_join(crumbs.flat_map.with_index { |crumb, index| [ (separator if index.positive?), crumb ].compact })
      end
    end

    private

    def separator
      tag.span("/", class: "text-taupe-300 dark:text-ink-300")
    end
  end
end
