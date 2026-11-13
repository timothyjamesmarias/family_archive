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

    def initialize(card:, return_to:)
      @card = card
      @return_to = return_to
    end

    def person_id = @card.person[:id]

    def label
      name = [ @card.person[:givenName], @card.person[:surname] ].compact_blank.join(" ")
      "Actions for #{name.presence || 'this person'}"
    end

    def items
      [
        [ "Edit", helpers.edit_family_tree_person_path(person_id, return_to: @return_to) ],
        *RELATIVES.map { |kind, caption| [ caption, helpers.new_family_tree_person_relative_path(person_id, kind:, return_to: @return_to) ] },
        [ "Delete", helpers.delete_family_tree_person_path(person_id, return_to: @return_to) ]
      ]
    end
  end
end
