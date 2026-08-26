# Ingests uploaded files: creates the artifact with its files on upload, or
# appends files to an existing artifact. Storage and thumbnails are Active
# Storage's job — attaching enqueues the preprocessed :thumb variant.
class Artifact::Uploader
  MAX_SLUG_ATTEMPTS = 10

  def upload(files:, artifact_type:, title: nil, original_date_string: nil)
    raise InvalidArgumentError.new("At least one file is required", field: "files") if files.empty?

    ApplicationRecord.transaction do
      artifact = Artifact.create!(
        slug: generate_slug,
        artifact_type: artifact_type,
        title: title,
        original_date_string: original_date_string
      )
      attach_all(artifact, files, from_sequence: 1)
      artifact
    end
  end

  def add_files(artifact_id, files)
    artifact = Artifact.includes(:files).find_by(id: artifact_id)
    raise NotFoundError, "Artifact not found with id: #{artifact_id}" unless artifact
    raise InvalidArgumentError.new("At least one file is required", field: "files") if files.empty?

    next_sequence = (artifact.files.map(&:file_sequence).max || 0) + 1
    ApplicationRecord.transaction { attach_all(artifact, files, from_sequence: next_sequence) }
    artifact.reload
  end

  private

  def attach_all(artifact, files, from_sequence:)
    files.each_with_index do |upload, index|
      record = artifact.files.create!(file_sequence: from_sequence + index)
      record.file.attach(upload)
    end
  end

  def generate_slug
    MAX_SLUG_ATTEMPTS.times do
      slug = SecureRandom.uuid[0, 8]
      return slug unless Artifact.exists?(slug: slug)
    end
    raise "Failed to generate unique slug after #{MAX_SLUG_ATTEMPTS} attempts"
  end
end
