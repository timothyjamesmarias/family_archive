require "test_helper"

class AnnotationTest < ActiveSupport::TestCase
  def coordinate_errors(x, y)
    annotation = Annotation.new(x_coord: x, y_coord: y)
    annotation.validate
    annotation.errors.attribute_names & %i[x_coord y_coord]
  end

  test "coordinates must be fractions of the image" do
    assert_empty coordinate_errors(0, 1)
    assert_equal [ :x_coord ], coordinate_errors(1.5, 0.5)
    assert_equal [ :y_coord ], coordinate_errors(0.5, nil)
  end

  test "marker offsets are percentages, with a missing coordinate at the edge" do
    annotation = Annotation.new(x_coord: 0.25, y_coord: nil)

    assert_equal [ 25.0, 0.0 ], [ annotation.left_percent, annotation.top_percent ]
  end
end
