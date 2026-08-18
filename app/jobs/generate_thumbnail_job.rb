# Generates a thumbnail for an artifact's primary file, skipping files that
# already have one.
class GenerateThumbnailJob < ApplicationJob
  queue_as :default

  def perform(artifact_id, size = ThumbnailGenerator::MEDIUM)
    primary = load_primary_file(artifact_id)
    return unless primary

    if primary.thumbnail_path.present?
      Rails.logger.debug { "Thumbnail already exists for file #{primary.id}; skipping" }
      return
    end

    result = ThumbnailGenerator.new.generate(primary, size)
    unless result
      Rails.logger.warn(
        "Thumbnail not generated for file #{primary.id}: unsupported type or source too large"
      )
      return
    end

    primary.update!(thumbnail_path: result[:path], thumbnail_size: result[:size_spec])
    Rails.logger.info("Generated thumbnail for file #{primary.id} at #{result[:path]}")
  end

  private

  def load_primary_file(artifact_id)
    artifact = Artifact.includes(:files).find_by(id: artifact_id)
    unless artifact
      Rails.logger.warn("Artifact #{artifact_id} not found for thumbnail job")
      return nil
    end
    primary = artifact.primary_file
    Rails.logger.debug { "No primary file for artifact #{artifact_id}; skipping" } unless primary
    primary
  end
end
