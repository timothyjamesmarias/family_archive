# Bulk thumbnail operations for the admin utilities screen: stats, backfill of
# missing thumbnails, and full regeneration. All work is enqueued, never done
# inline.
class ThumbnailBackfill
  def backfill_all(size = ThumbnailGenerator::MEDIUM)
    candidates = image_artifacts.select { |candidate| candidate[:primary].thumbnail_path.nil? }
    enqueue_all(candidates, size, GenerateThumbnailJob)
  end

  def regenerate_all(size = ThumbnailGenerator::MEDIUM)
    enqueue_all(image_artifacts, size, RegenerateThumbnailJob)
  end

  def stats
    total_artifacts = Artifact.count
    candidates = image_artifacts
    with_thumbnails = candidates.count { |c| c[:primary].thumbnail_path.present? }
    too_large = candidates.count do |c|
      c[:primary].file_size > ThumbnailGenerator::MAX_SOURCE_SIZE_BYTES
    end

    {
      total_artifacts: total_artifacts,
      total_image_artifacts: candidates.size,
      with_thumbnails: with_thumbnails,
      without_thumbnails: candidates.size - with_thumbnails,
      too_large_to_process: too_large
    }
  end

  private

  def enqueue_all(candidates, size, job_class)
    partitioned = candidates.partition do |candidate|
      candidate[:primary].file_size <= ThumbnailGenerator::MAX_SOURCE_SIZE_BYTES
    end
    runnable, skipped = partitioned

    runnable.each { |candidate| job_class.perform_later(candidate[:artifact].id, size) }

    { total_artifacts: candidates.size, jobs_enqueued: runnable.size, skipped: skipped.size }
  end

  # Artifacts whose primary (sequence 1) file is a supported image, with that file.
  def image_artifacts
    Artifact.includes(:files).filter_map do |artifact|
      primary = artifact.primary_file
      next unless primary && ThumbnailGenerator.supported?(primary.mime_type)

      { artifact: artifact, primary: primary }
    end
  end
end
