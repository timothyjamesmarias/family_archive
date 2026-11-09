module Admin
  # The admin's button looks, named once. Renders a link with href:, a
  # button_to form with to:, and a plain <button> otherwise. Same vocabulary
  # as Ui::ButtonComponent, with the admin's slate classes in place of recipes.
  class ButtonComponent < ApplicationComponent
    VARIANT_CLASSES = {
      primary: "rounded bg-slate-900 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700 dark:bg-slate-700 dark:hover:bg-slate-600 cursor-pointer",
      secondary: "rounded border border-slate-300 px-4 py-2 text-sm hover:bg-slate-100 dark:border-slate-600 dark:hover:bg-slate-800 cursor-pointer",
      danger: "text-sm text-red-700 underline dark:text-red-400 cursor-pointer"
    }.freeze

    def initialize(variant: :primary, href: nil, to: nil, **attributes)
      @href = href
      @to = to
      @attributes = attributes.merge(class: class_names(VARIANT_CLASSES.fetch(variant), attributes[:class]))
    end

    def call
      if @href
        link_to content, @href, **@attributes
      elsif @to
        button_to content, @to, **@attributes
      else
        tag.button content, type: @attributes.fetch(:type, "button"), **@attributes.except(:type)
      end
    end
  end
end
