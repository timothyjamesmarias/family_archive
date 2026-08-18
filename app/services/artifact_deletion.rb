# Removes artifacts and individual artifact files, keeping the stored objects
# and the database rows in step.
class ArtifactDeletion
  # Storage is cleared BEFORE the DB row; storage failures are logged but never
  # abort the DB delete.
  def destroy_artifact(artifact_id)
    artifact = Artifact.includes(:files).find_by(id: artifact_id)
    return false unless artifact

    if artifact.files.any?
      artifact.files.each do |file|
        try_delete_from_storage(file.storage_path)
        try_delete_from_storage(file.thumbnail_path) if file.thumbnail_path
      end
    else
      try_delete_from_storage(artifact.storage_path)
    end

    artifact.destroy!
    true
  end

  # Delete one file: DB update (remove + resequence) happens BEFORE the storage
  # delete — the reverse of whole-artifact delete, matching the original.
  def destroy_file(artifact_id, file_id)
    artifact = Artifact.includes(:files).find_by(id: artifact_id)
    raise NotFoundError, "Artifact not found with id: #{artifact_id}" unless artifact

    file = artifact.files.find { |f| f.id == file_id.to_i }
    raise NotFoundError, "File not found with id: #{file_id}" unless file
    if artifact.files.size <= 1
      raise ConflictError.new(
        "Cannot delete the only file. Please delete the entire artifact instead.",
        field: "files"
      )
    end

    file.destroy!
    artifact.files.reject { |f| f.id == file.id }
      .sort_by(&:file_sequence)
      .each_with_index { |remaining, index| remaining.update!(file_sequence: index + 1) }

    try_delete_from_storage(file.storage_path)
    try_delete_from_storage(file.thumbnail_path) if file.thumbnail_path
    true
  end

  private

  def try_delete_from_storage(path)
    Storage.delete(path)
  rescue StandardError => error
    Rails.logger.error("Failed to delete file from storage (#{path}): #{error.message}")
  end
end
