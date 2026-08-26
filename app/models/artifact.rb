class Artifact < ApplicationRecord
  MAX_FILE_SIZE_BYTES = 50 * 1024 * 1024

  has_one :transcription, dependent: :destroy
  has_many :commentaries, dependent: :destroy
  has_many :files, -> { order(:file_sequence) }, class_name: "ArtifactFile", dependent: :destroy

  validates :slug, presence: true, uniqueness: true
  validates :artifact_type, inclusion: { in: ArtifactType::KEYS }

  scope :of_type, ->(key) { where(artifact_type: key) }
  # OTHER has no public route, so public listings must not link to it.
  scope :browsable, -> { where(artifact_type: ArtifactType.browsable.map(&:key)) }

  def type
    ArtifactType.fetch(artifact_type)
  end

  def primary_file
    files.find { |file| file.file_sequence == 1 }
  end

  # Removes one file and closes the sequence gap. The stored object is purged
  # by the attachment when the row goes.
  def remove_file!(file_id)
    file = files.find { |f| f.id == file_id.to_i }
    raise NotFoundError, "File not found with id: #{file_id}" unless file
    if files.size <= 1
      raise ConflictError.new(
        "Cannot delete the only file. Please delete the entire artifact instead.",
        field: "files"
      )
    end

    file.destroy!
    files.reject { |f| f.id == file.id }
      .sort_by(&:file_sequence)
      .each_with_index { |remaining, index| remaining.update!(file_sequence: index + 1) }
  end
end
