module Ui
  class ButtonComponentPreview < ViewComponent::Preview
    # @label Variants
    def variants
      render_with_template
    end

    # @label Sizes
    def sizes
      render_with_template
    end
  end
end
