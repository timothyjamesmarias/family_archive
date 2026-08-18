# Regenerates the thumbnail for an artifact's primary file, replacing any
# existing one.
class RegenerateThumbnailJob < ApplicationJob
  queue_as :default

  def perform(artifact_id, size = ThumbnailGenerator::MEDIUM)
    artifact = Artifact.includes(:files).find_by(id: artifact_id)
    unless artifact
      Rails.logger.warn("Artifact #{artifact_id} not found for thumbnail job")
      return
    end
    primary = artifact.primary_file
    return unless primary

    # Generate before deleting: a source that has become unsupported or
    # oversized would otherwise leave the artifact with no thumbnail at all.
    generator = ThumbnailGenerator.new
    result = generator.generate(primary, size)
    unless result
      Rails.logger.warn("Thumbnail not regenerated for file #{primary.id}; keeping the existing one")
      return
    end

    previous_path = primary.thumbnail_path
    primary.update!(thumbnail_path: result[:path], thumbnail_size: result[:size_spec])
    generator.delete(previous_path) if previous_path.present? && previous_path != result[:path]
    Rails.logger.info("Regenerated thumbnail for file #{primary.id} at #{result[:path]}")
  end
end
