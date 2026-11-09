class Annotation < ApplicationRecord
  belongs_to :artifact_file

  validates :annotation_text, presence: true
  # Fractions of the image's width and height, so a marker keeps its place at
  # any rendered size.
  validates :x_coord, :y_coord, numericality: { in: 0..1 }
end
