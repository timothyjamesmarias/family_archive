require "test_helper"

# Edge geometry in the layout's own units: x in slots, y in rows, card
# centres at integer rows. Cards paint over the segments, so lines may run
# centre to centre.
class FamilyTree::EdgesTest < ActiveSupport::TestCase
  def edges(positions, units)
    laid = positions.transform_values { |(x, generation)| FamilyTree::Layout::Position.new(x:, generation:) }
    built = units.map do |id, (parents, children)|
      FamilyTree::Layout::Unit.new(id:, parent_ids: parents, child_ids: children)
    end
    FamilyTree::Edges.new(positions: laid, units: built).segments
  end

  def seg(kind, x1, y1, x2, y2) = FamilyTree::Edges::Segment.new(kind:, x1:, y1:, x2:, y2:)

  test "a couple with one child: marriage line, drop, stub, no bus" do
    segments = edges({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 1 ] }, u: [ %i[F M], %i[C] ])

    assert_equal [
      seg(:marriage, 0, 0, 1, 0),
      seg(:drop, 0.5, 0, 0.5, 0.6),
      seg(:stub, 0.5, 0.6, 0.5, 1)
    ], segments
  end

  test "several children share a bus" do
    segments = edges({ F: [ 1, 0 ], M: [ 2, 0 ], A: [ 0, 1 ], B: [ 1, 1 ], C: [ 3, 1 ] }, u: [ %i[F M], %i[A B C] ])

    assert_includes segments, seg(:bus, 0, 0.6, 3, 0.6)
    assert_equal 3, segments.count { |s| s.kind == :stub }
  end

  test "a single parent drops from their own card" do
    segments = edges({ M: [ 0.5, 0 ], A: [ 0, 1 ], B: [ 1, 1 ] }, u: [ %i[M], %i[A B] ])

    assert_includes segments, seg(:drop, 0.5, 0, 0.5, 0.6)
    assert_not segments.any? { |s| s.kind == :marriage }
  end

  test "parentless siblings get a bus and stubs but no drop" do
    segments = edges({ A: [ 0, 0 ], B: [ 1, 0 ] }, u: [ [], %i[A B] ])

    assert_equal [ seg(:bus, 0, -0.4, 1, -0.4), seg(:stub, 0, -0.4, 0, 0), seg(:stub, 1, -0.4, 1, 0) ], segments
  end

  test "the bus reaches a drop that falls outside the children" do
    segments = edges({ P: [ 2, 0 ], S: [ 3, 0 ], C: [ 0, 1 ] }, u: [ %i[P S], %i[C] ])

    assert_includes segments, seg(:bus, 0, 0.6, 2.5, 0.6)
  end

  test "overlapping buses on one row take separate lanes" do
    segments = edges(
      { A1: [ 0, 0 ], A2: [ 1, 0 ], B1: [ 4, 0 ], B2: [ 5, 0 ], a: [ 0, 1 ], a2: [ 3, 1 ], b: [ 2, 1 ], b2: [ 5, 1 ] },
      a: [ %i[A1 A2], %i[a a2] ], b: [ %i[B1 B2], %i[b b2] ]
    )

    assert_includes segments, seg(:bus, 0, 0.6, 3, 0.6)
    assert_includes segments, seg(:bus, 2, 0.7, 5, 0.7)
  end

  test "a child more than one row down gets a longer drop to a bus above its own row" do
    segments = edges({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 2 ] }, u: [ %i[F M], %i[C] ])

    assert_includes segments, seg(:drop, 0.5, 0, 0.5, 1.6)
    assert_includes segments, seg(:stub, 0.5, 1.6, 0.5, 2)
  end

  test "a child on the same row or above is linked directly" do
    segments = edges({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 3, 0 ] }, u: [ %i[F M], %i[C] ])

    assert_equal [ seg(:marriage, 0, 0, 1, 0), seg(:link, 0.5, 0, 3, 0) ], segments
  end
end
