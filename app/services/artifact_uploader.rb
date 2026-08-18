# Ingests uploaded files: creates the artifact with its files on upload, or
# appends files to an existing artifact, enqueueing a thumbnail job when the
# primary file is a supported image.
class ArtifactUploader
  MAX_SLUG_ATTEMPTS = 10
  DEFAULT_MIME = "application/octet-stream"

  def upload(files:, artifact_type:, title: nil, original_date_string: nil)
    raise InvalidArgumentError.new("At least one file is required", field: "files") if files.empty?

    slug = generate_slug
    primary = files.first
    year = Time.current.year
    type_segment = artifact_type.downcase

    primary_path = Storage.store(primary,
      "artifacts/#{type_segment}/#{year}/#{slug}.#{extension_of(primary)}")

    artifact = Artifact.create!(
      slug: slug,
      artifact_type: artifact_type,
      title: title,
      storage_path: primary_path,
      mime_type: mime_of(primary),
      file_size: primary.size,
      original_date_string: original_date_string
    )

    files.each_with_index do |file, index|
      storage_path =
        if index.zero?
          primary_path
        else
          Storage.store(file,
            "artifacts/#{type_segment}/#{year}/#{slug}-#{index + 1}.#{extension_of(file)}")
        end
      artifact.files.create!(
        file_sequence: index + 1,
        storage_path: storage_path,
        mime_type: mime_of(file),
        file_size: file.size
      )
    end

    if ThumbnailGenerator.supported?(mime_of(primary))
      GenerateThumbnailJob.perform_later(artifact.id, ThumbnailGenerator::MEDIUM)
    end

    artifact
  end

  def add_files(artifact_id, files)
    artifact = Artifact.includes(:files).find_by(id: artifact_id)
    raise NotFoundError, "Artifact not found with id: #{artifact_id}" unless artifact
    raise InvalidArgumentError.new("At least one file is required", field: "files") if files.empty?

    max_sequence = artifact.files.map(&:file_sequence).max || 0
    year = Time.current.year
    type_segment = artifact.artifact_type.downcase

    needs_thumbnail = files.each_with_index.map do |file, index|
      sequence = max_sequence + index + 1
      storage_path = Storage.store(file,
        "artifacts/#{type_segment}/#{year}/#{artifact.slug}-#{sequence}.#{extension_of(file)}")
      artifact.files.create!(
        file_sequence: sequence,
        storage_path: storage_path,
        mime_type: mime_of(file),
        file_size: file.size
      )
      ThumbnailGenerator.supported?(mime_of(file))
    end.any?

    if needs_thumbnail
      RegenerateThumbnailJob.perform_later(artifact.id, ThumbnailGenerator::MEDIUM)
    end

    artifact.reload
  end

  private

  def extension_of(file)
    extension = File.extname(file.original_filename.to_s).delete_prefix(".")
    extension.presence || "bin"
  end

  def mime_of(file)
    file.content_type.presence || DEFAULT_MIME
  end

  def generate_slug
    MAX_SLUG_ATTEMPTS.times do
      slug = SecureRandom.uuid[0, 8]
      return slug unless Artifact.exists?(slug: slug)
    end
    raise "Failed to generate unique slug after #{MAX_SLUG_ATTEMPTS} attempts"
  end
end
