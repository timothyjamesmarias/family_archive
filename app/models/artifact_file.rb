class ArtifactFile < ApplicationRecord
  THUMBNAIL_SIZE = 300
  THUMBNAIL_QUALITY = 85

  belongs_to :artifact
  has_many :annotations, dependent: :destroy

  # `preprocessed: true` enqueues the transform right after upload, so list
  # pages never pay for on-demand generation.
  has_one_attached :file do |attachable|
    attachable.variant :thumb, resize_to_limit: [ THUMBNAIL_SIZE, THUMBNAIL_SIZE ],
      format: :jpeg, saver: { quality: THUMBNAIL_QUALITY }, preprocessed: true
  end

  def image?
    file.attached? && file.blob.content_type.to_s.start_with?("image/")
  end

  # A variant can only be generated for image types vips understands.
  def thumbnail?
    file.attached? && file.blob.representable?
  end
end
