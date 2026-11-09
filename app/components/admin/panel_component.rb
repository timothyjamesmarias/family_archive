module Admin
  # The admin's bordered sheet. Extra classes and data attributes pass through.
  class PanelComponent < ApplicationComponent
    def initialize(**attributes)
      @attributes = attributes
    end

    def call
      tag.div content, **@attributes, class: class_names(
        "rounded border border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-slate-900", @attributes[:class]
      )
    end
  end
end
