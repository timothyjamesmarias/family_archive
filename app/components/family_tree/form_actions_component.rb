module FamilyTree
  # A dialog form's footer: Cancel closes the dialog; the submit, when there
  # is one, says what the form does.
  class FormActionsComponent < ApplicationComponent
    def initialize(submit: nil, variant: :primary)
      @submit = submit
      @variant = variant
    end

    def call
      tag.div(class: "tree-form-actions") do
        safe_join([
          render(Ui::ButtonComponent.new(variant: :secondary, size: :sm, type: "button", data: { action: "tree-dialog#close" }).with_content("Cancel")),
          (render(Ui::ButtonComponent.new(variant: @variant, size: :sm, type: "submit").with_content(@submit)) if @submit)
        ].compact)
      end
    end
  end
end
