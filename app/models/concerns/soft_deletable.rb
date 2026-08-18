# destroy marks the row rather than removing it, and every query excludes
# marked rows. Use with_deleted to include them.
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    default_scope { where(deleted_at: nil) }
    scope :with_deleted, -> { unscope(where: :deleted_at) }
  end

  def destroy
    update!(deleted_at: Time.current)
    self
  end

  def deleted?
    deleted_at.present?
  end
end
