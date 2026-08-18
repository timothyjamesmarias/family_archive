class Artifact < ApplicationRecord
  MAX_FILE_SIZE_BYTES = 50 * 1024 * 1024

  has_one :transcription, dependent: :destroy
  has_many :commentaries, dependent: :destroy
  has_many :files, -> { order(:file_sequence) }, class_name: "ArtifactFile", dependent: :destroy

  validates :slug, presence: true, uniqueness: true
  validates :artifact_type, inclusion: { in: ArtifactType::KEYS }

  scope :of_type, ->(key) { where(artifact_type: key) }

  def type
    ArtifactType.fetch(artifact_type)
  end

  def primary_file
    files.find { |file| file.file_sequence == 1 }
  end
end
