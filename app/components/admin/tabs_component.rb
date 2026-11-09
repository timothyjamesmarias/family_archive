module Admin
  # A row of link tabs over a hairline. Same vocabulary as Ui::TabsComponent.
  class TabsComponent < ApplicationComponent
    class TabComponent < ApplicationComponent
      def initialize(label:, href:, active: false)
        @label = label
        @href = href
        @active = active
      end

      def call
        link_to @label, @href, aria: { current: ("page" if @active) }, class: class_names(
          "-mb-px border-b-2 px-3 py-2",
          @active ? "border-slate-900 font-medium dark:border-slate-100" : "border-transparent text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-100"
        )
      end
    end

    renders_many :tabs, TabComponent

    def call
      tag.nav safe_join(tabs), aria: { label: "Tabs" },
        class: "mb-4 flex gap-1 border-b border-slate-200 text-sm dark:border-slate-800"
    end
  end
end
