module FamilyTree
  # The per-card menu in edit mode: a native <details> (no script, sits on
  # the card inside the transformed stage) listing links that load their
  # form into the dialog's frame. Every link carries the chart URL to come
  # back to.
  class ActionMenuComponent < ApplicationComponent
    RELATIVES = {
      "child" => "Add child", "spouse" => "Add spouse", "parent" => "Add parent",
      "existing_parent" => "Link existing parent", "sibling" => "Add sibling"
    }.freeze

    def initialize(person_id:, return_to:)
      @person_id = person_id
      @return_to = return_to
    end

    def items
      [
        [ "Edit", helpers.edit_family_tree_person_path(@person_id, return_to: @return_to) ],
        *RELATIVES.map { |kind, caption| [ caption, helpers.new_family_tree_person_relative_path(@person_id, kind:, return_to: @return_to) ] },
        [ "Delete", helpers.delete_family_tree_person_path(@person_id, return_to: @return_to) ]
      ]
    end
  end
end
