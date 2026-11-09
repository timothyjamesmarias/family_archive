class Annotation < ApplicationRecord
  belongs_to :artifact_file

  validates :annotation_text, presence: true
  # Fractions of the image's width and height, so a marker keeps its place at
  # any rendered size.
  validates :x_coord, :y_coord, numericality: { in: 0..1 }

  # Marker offsets as CSS percentages. The columns are nullable, and a missing
  # coordinate pins the marker to the edge rather than breaking the page.
  # Scaled as decimals before converting, so 0.28 renders 28.0, not
  # 28.000000000000004.
  def left_percent
    percent(x_coord)
  end

  def top_percent
    percent(y_coord)
  end

  private

  def percent(fraction)
    ((fraction || 0) * 100).to_f
  end
end
