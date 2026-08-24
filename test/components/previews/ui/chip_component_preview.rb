module Ui
  class ChipComponentPreview < ViewComponent::Preview
    # @label Type taxonomy
    def types
      render_with_template
    end

    # @label Status chips
    def statuses
      render_with_template
    end
  end
end
