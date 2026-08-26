module Ui
  # Renders an <a> when given href, a <button> otherwise. Props map to the
  # recipe classes in public.css; keep the two in step with the React twin.
  class ButtonComponent < ApplicationComponent
    VARIANT_CLASSES = {
      primary: "btn-primary",
      secondary: "btn-secondary",
      quiet: "btn-quiet",
      danger: "btn-danger"
    }.freeze

    SIZE_CLASSES = { lg: "btn-lg", md: nil, sm: "btn-sm" }.freeze

    def initialize(variant: :primary, size: :md, href: nil, **attributes)
      @href = href
      @attributes = attributes
      @attributes[:class] = class_names(
        VARIANT_CLASSES.fetch(variant),
        SIZE_CLASSES.fetch(size),
        attributes[:class]
      )
    end

    def call
      if @href
        link_to content, @href, **@attributes
      else
        tag.button content, type: @attributes.fetch(:type, "button"), **@attributes.except(:type)
      end
    end
  end
end
