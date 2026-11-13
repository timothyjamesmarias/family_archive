module FamilyTree
  # Father or mother, for the forms that add or link a parent.
  class RoleChoiceComponent < ApplicationComponent
    ROLES = { "FATHER" => "Father", "MOTHER" => "Mother" }.freeze

    def initialize(role:)
      @role = ROLES.key?(role) ? role : "FATHER"
    end

    def call
      tag.fieldset(class: "field") do
        safe_join([
          tag.legend("Role", class: "field-label"),
          tag.div(class: "tree-form-choices") do
            safe_join(ROLES.map do |code, caption|
              tag.label(class: "tree-form-choice") { safe_join([ radio_button_tag(:role, code, code == @role), " ", caption ]) }
            end)
          end
        ])
      end
    end
  end
end
