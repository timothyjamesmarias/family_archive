class Article < ApplicationRecord
  SLUG_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  has_rich_text :content
  has_many :embeds, as: :owner
  after_save :sync_embeds
  after_destroy { embeds.each { it.release_from(self) } }

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

  private

  # Claims embeds the body references and releases the ones edited out, so the
  # embeds table holds exactly what articles show.
  # ponytail: an embed inserted into a new article that is never saved stays
  # ownerless; sweep `Embed.where(owner: nil)` by age if those pile up.
  def sync_embeds
    referenced = Array(content.body&.attachables).grep(Embed).map(&:id)
    embeds.where.not(id: referenced).each { it.release_from(self) }
    Embed.where(id: referenced, owner: nil).update_all(owner_type: self.class.name, owner_id: id)
  end
end
