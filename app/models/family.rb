class Family < ApplicationRecord
  include SoftDeletable

  belongs_to :marriage_place, class_name: "Place", optional: true
  has_many :members, class_name: "FamilyMember", dependent: :destroy

  # Includes soft-deleted rows; see the matching validation on Individual.
  validates :gedcom_id, uniqueness: { conditions: -> { with_deleted } }, allow_nil: true

  # A family has no name of its own, so lists label it by its parents.
  def display_name
    parents = members
      .select(&:parent_role?)
      .filter_map { |member| member.individual&.display_name }
    parents.any? ? parents.join(" & ") : (gedcom_id || "Family ##{id}")
  end
end
