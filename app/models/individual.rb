class Individual < ApplicationRecord
  include SoftDeletable

  SEXES = %w[M F].freeze

  has_many :family_memberships, class_name: "FamilyMember", dependent: :destroy
  has_many :events, class_name: "IndividualEvent", dependent: :destroy

  # Soft-deleted rows are included deliberately: the default scope hides them,
  # but the database's unique index does not, so skipping them turns a reused
  # id into a driver error instead of a validation message.
  validates :gedcom_id, uniqueness: { conditions: -> { with_deleted } }, allow_nil: true
  validates :sex, inclusion: { in: SEXES }, allow_nil: true

  scope :tree_roots, -> { where(is_tree_root: true) }

  def display_name
    name = [ given_name, surname ].compact_blank.join(" ").strip
    name.presence || gedcom_id || "Individual ##{id}"
  end
end
