require "test_helper"

# Pixel geometry from FamilyTree::Metrics: card centres at 128 + 230·x, card
# tops at 28 + 166·generation, cards 76 tall. A couple's bracket hangs 34
# below their cards, a bus runs 28 above the children's.
class FamilyTree::EdgesTest < ActiveSupport::TestCase
  def edges(positions, units)
    laid = positions.transform_values { |(x, generation)| FamilyTree::Layout::Position.new(x:, generation:) }
    built = units.map do |id, (parents, children)|
      FamilyTree::Layout::Unit.new(id:, parent_ids: parents, child_ids: children)
    end
    FamilyTree::Edges.new(positions: laid, units: built).segments
  end

  def seg(kind, x1, y1, x2, y2) = FamilyTree::Edges::Segment.new(kind:, x1:, y1:, x2:, y2:)

  test "a couple with one child: bracket, drop, stub, no bus" do
    segments = edges({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 1 ] }, u: [ %i[F M], %i[C] ])

    assert_equal [
      seg(:marriage, 128, 104, 128, 138),
      seg(:marriage, 128, 138, 358, 138),
      seg(:marriage, 358, 138, 358, 104),
      seg(:drop, 243, 138, 243, 166),
      seg(:stub, 243, 166, 243, 194)
    ], segments
  end

  test "several children share a bus" do
    segments = edges({ F: [ 1, 0 ], M: [ 2, 0 ], A: [ 0, 1 ], B: [ 1, 1 ], C: [ 3, 1 ] }, u: [ %i[F M], %i[A B C] ])

    assert_includes segments, seg(:bus, 128, 166, 818, 166)
    assert_equal 3, segments.count { |s| s.kind == :stub }
  end

  test "a lone parent drops straight off their card, with no bracket" do
    segments = edges({ M: [ 0.5, 0 ], A: [ 0, 1 ], B: [ 1, 1 ] }, u: [ %i[M], %i[A B] ])

    assert_includes segments, seg(:drop, 243, 104, 243, 166)
    assert_not segments.any? { |s| s.kind == :marriage }
  end

  test "siblings whose parents are not loaded get no lines" do
    segments = edges({ A: [ 0, 0 ], B: [ 1, 0 ] }, u: [ [], %i[A B] ])

    assert_empty segments
  end

  test "the bus reaches a drop that falls outside the children" do
    segments = edges({ P: [ 2, 0 ], S: [ 3, 0 ], C: [ 0, 1 ] }, u: [ %i[P S], %i[C] ])

    assert_includes segments, seg(:bus, 128, 166, 703, 166)
  end

  test "overlapping buses on one row take separate lanes" do
    segments = edges(
      { A1: [ 0, 0 ], A2: [ 1, 0 ], B1: [ 4, 0 ], B2: [ 5, 0 ], a: [ 0, 1 ], a2: [ 3, 1 ], b: [ 2, 1 ], b2: [ 5, 1 ] },
      a: [ %i[A1 A2], %i[a a2] ], b: [ %i[B1 B2], %i[b b2] ]
    )

    assert_includes segments, seg(:bus, 128, 166, 818, 166)
    assert_includes segments, seg(:bus, 588, 156, 1278, 156)
  end

  # Four couples whose children interleave need four lanes; the bracket sits
  # at 138, so the lanes squeeze into the 28px above the bus line rather
  # than climbing past it.
  test "many overlapping buses stay below the brackets" do
    positions = { A1: [ 0, 0 ], A2: [ 1, 0 ], B1: [ 2, 0 ], B2: [ 3, 0 ], C1: [ 4, 0 ], C2: [ 5, 0 ], D1: [ 6, 0 ], D2: [ 7, 0 ],
                  a1: [ 0, 1 ], b1: [ 1, 1 ], c1: [ 2, 1 ], d1: [ 3, 1 ], d2: [ 4, 1 ], c2: [ 5, 1 ], b2: [ 6, 1 ], a2: [ 7, 1 ] }
    segments = edges(positions,
      a: [ %i[A1 A2], %i[a1 a2] ], b: [ %i[B1 B2], %i[b1 b2] ], c: [ %i[C1 C2], %i[c1 c2] ], d: [ %i[D1 D2], %i[d1 d2] ])

    bus_ys = segments.select { |s| s.kind == :bus }.map(&:y1).sort.reverse
    assert_equal [ 166, 158, 150, 142 ], bus_ys
    assert segments.select { |s| s.kind == :drop }.all? { |s| s.y2 > s.y1 }, "every drop still goes down"
  end

  test "a child more than one row down gets a longer drop to a bus above its own row" do
    segments = edges({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 2 ] }, u: [ %i[F M], %i[C] ])

    assert_includes segments, seg(:drop, 243, 138, 243, 332)
    assert_includes segments, seg(:stub, 243, 332, 243, 360)
  end

  test "a child on the same row or above is linked directly" do
    segments = edges({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 3, 0 ] }, u: [ %i[F M], %i[C] ])

    assert_equal seg(:link, 243, 138, 818, 28), segments.last
    assert_equal 4, segments.size
  end
end
