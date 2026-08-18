class Article < ApplicationRecord
  SLUG_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: SLUG_PATTERN, message: "use lowercase letters, numbers and hyphens only" }

  # Must match the published? getter, or an article published at exactly `now`
  # is listed but 404s when opened.
  scope :published, -> { where(published_at: ..Time.current) }
  scope :drafts, -> { where(published_at: nil).or(where(published_at: Time.current..)) }

  def published?
    published_at.present? && published_at <= Time.current
  end

  def draft?
    !published?
  end

  def publish!
    update!(published_at: Time.current)
  end

  def unpublish!
    update!(published_at: nil)
  end
end
