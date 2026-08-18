class Annotation < ApplicationRecord
  belongs_to :artifact_file

  validates :annotation_text, presence: true
end
