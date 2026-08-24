# The scan on its mat: thumbnail variant when one exists, the raw image as
# a fallback, otherwise the type icon. Never cropped to fill — a document's
# shape is information.
class ArtifactThumbnailComponent < ApplicationComponent
  def initialize(artifact:, icon_size: "w-12 h-12")
    @artifact = artifact
    @icon_size = icon_size
  end

  private

  attr_reader :artifact, :icon_size

  def file
    artifact.files.first
  end

  def image_source
    return unless file
    return file.file.variant(:thumb) if file.thumbnail?

    file.file if file.image?
  end

  def alt_text
    artifact.title || "Untitled #{artifact.type.display_name}"
  end
end
