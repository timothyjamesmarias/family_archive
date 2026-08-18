class FamilyMember < ApplicationRecord
  include SoftDeletable

  ROLES = %w[FATHER MOTHER CHILD].freeze
  PARENT_ROLES = %w[FATHER MOTHER].freeze

  self.primary_key = [ :family_id, :individual_id, :role ]

  belongs_to :family
  belongs_to :individual

  validates :role, inclusion: { in: ROLES }

  scope :parents, -> { where(role: PARENT_ROLES) }
  scope :children, -> { where(role: "CHILD") }

  def parent_role?
    PARENT_ROLES.include?(role)
  end
end
