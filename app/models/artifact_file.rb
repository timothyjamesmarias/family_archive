class ArtifactFile < ApplicationRecord
  belongs_to :artifact
  has_many :annotations, dependent: :destroy

  def image?
    mime_type.to_s.start_with?("image/")
  end
end
