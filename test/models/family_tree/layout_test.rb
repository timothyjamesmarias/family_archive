require "test_helper"

class FamilyTree::LayoutTest < ActiveSupport::TestCase
  # Units are written unit_id: [parent_ids, child_ids]; order is meaning
  # (first parent left, children in birth order). Ids are symbols so the
  # sketches read like a chart; the layout treats ids as opaque keys.
  def layout(individual_ids: nil, **units)
    built = units.map do |id, (parents, children)|
      FamilyTree::Layout::Unit.new(id:, parent_ids: parents, child_ids: children)
    end
    ids = individual_ids || built.flat_map { |u| u.parent_ids + u.child_ids }.uniq
    FamilyTree::Layout.new(individual_ids: ids, units: built)
  end

  # expected = { id => [x, generation] }
  def assert_positions(expected, result)
    actual = result.positions
    assert_equal expected.keys.sort, actual.keys.sort, "positioned the wrong set of people\n#{result.sketch}"
    expected.each do |id, (x, generation)|
      assert_in_delta x, actual[id].x, 1e-9, "x of #{id}\n#{result.sketch}"
      assert_equal generation, actual[id].generation, "generation of #{id}\n#{result.sketch}"
    end
  end

  test "a single person sits at the origin" do
    result = layout(individual_ids: [ :P ])

    assert_positions({ P: [ 0, 0 ] }, result)
    assert_equal 1, result.width
    assert_equal 1, result.height
  end

  test "a couple shares a row, first parent on the left" do
    result = layout(u: [ [ :F, :M ], [] ])

    assert_positions({ F: [ 0, 0 ], M: [ 1, 0 ] }, result)
    assert_equal 2, result.width
    assert_equal 1, result.height
  end

  test "an only child is centred under the marriage" do
    result = layout(u: [ [ :F, :M ], [ :C ] ])

    assert_positions({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 1 ] }, result)
    assert_equal 2, result.width
    assert_equal 2, result.height
  end

  test "a married only child still sits under the marriage, the in-law beside them" do
    result = layout(u: [ [ :F, :M ], [ :C ] ], c: [ [ :C, :W ], [] ])

    assert_positions({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 1 ], W: [ 1.5, 1 ] }, result)
  end

  test "siblings take adjacent slots and the parents centre over them" do
    result = layout(u: [ [ :F, :M ], [ :A, :B, :C ] ])

    assert_positions({ F: [ 0.5, 0 ], M: [ 1.5, 0 ], A: [ 0, 1 ], B: [ 1, 1 ], C: [ 2, 1 ] }, result)
    assert_equal 3, result.width
  end

  test "a single parent is centred over the children" do
    result = layout(u: [ [ :M ], [ :A, :B ] ])

    assert_positions({ M: [ 0.5, 0 ], A: [ 0, 1 ], B: [ 1, 1 ] }, result)
  end

  test "parentless siblings stay together on the top row" do
    result = layout(u: [ [], [ :A, :B, :C ] ])

    assert_positions({ A: [ 0, 0 ], B: [ 1, 0 ], C: [ 2, 0 ] }, result)
    assert_equal 1, result.height
  end

  test "children keep their given order left to right" do
    result = layout(u: [ [ :F, :M ], [ :C, :A, :B ] ])

    assert_positions({ F: [ 0.5, 0 ], M: [ 1.5, 0 ], C: [ 0, 1 ], A: [ 1, 1 ], B: [ 2, 1 ] }, result)
  end

  test "a child listed twice in one unit is one child" do
    result = layout(g: [ [], [ :A, :B, :B ] ])

    assert_positions({ A: [ 0, 0 ], B: [ 1, 0 ] }, result)
  end

  test "units that share a seat keep their input order" do
    result = layout(sons: [ [ :P ], [ :c1, :c2 ] ], daughters: [ [ :P ], [ :d1 ] ])

    assert_positions({ P: [ 1, 0 ], c1: [ 0, 1 ], c2: [ 1, 1 ], d1: [ 2, 1 ] }, result)
  end

  # Worked by hand: A's children sit at 0 and 1, so the A block centres on
  # 0.5. B's block is a sibling block (width 2 each, gap 0) so it starts at
  # 2.5, then its child b1 must clear a2 by the cousin gap (1 + 1 = 2), which
  # shifts the whole B subtree right by 0.5. The grandparents centre over
  # their children's own cards, A at 0 and B at 2.5: 1.25.
  test "cousins get an empty slot between them, siblings do not" do
    result = layout(
      g: [ [ :GF, :GM ], [ :A, :B ] ],
      a: [ [ :A, :SA ], [ :a1, :a2 ] ],
      b: [ [ :B, :SB ], [ :b1 ] ]
    )

    assert_positions({
      GF: [ 0.75, 0 ], GM: [ 1.75, 0 ],
      A: [ 0, 1 ], SA: [ 1, 1 ], B: [ 2.5, 1 ], SB: [ 3.5, 1 ],
      a1: [ 0, 2 ], a2: [ 1, 2 ], b1: [ 3, 2 ]
    }, result)
    assert_in_delta 4.5, result.width
    assert_equal 3, result.height
  end

  # Worked by hand: D's five children collide with B's, so the tidy tree
  # shifts D's subtree right by 3 and spreads that shift over the sibling in
  # between, moving C by 1.5. B stays put, centred over its own children.
  test "a shift between distant siblings is spread over the siblings in between" do
    result = layout(
      g: [ [ :GF, :GM ], [ :A, :B, :C, :D ] ],
      a: [ [ :A, :SA ], [ :a1 ] ],
      a1: [ [ :a1, :w1 ], [ :x1, :x2, :x3 ] ],
      b: [ [ :B, :SB ], [ :b1, :b2, :b3, :b4, :b5 ] ],
      d: [ [ :D, :SD ], [ :d1, :d2, :d3, :d4, :d5 ] ]
    )

    assert_positions({
      GF: [ 5.0, 0 ], GM: [ 6.0, 0 ],
      A: [ 0, 1 ], SA: [ 1, 1 ], B: [ 5.0, 1 ], SB: [ 6.0, 1 ], C: [ 8.5, 1 ], D: [ 11.0, 1 ], SD: [ 12.0, 1 ],
      a1: [ 0.5, 2 ], w1: [ 1.5, 2 ],
      b1: [ 3.5, 2 ], b2: [ 4.5, 2 ], b3: [ 5.5, 2 ], b4: [ 6.5, 2 ], b5: [ 7.5, 2 ],
      d1: [ 9.5, 2 ], d2: [ 10.5, 2 ], d3: [ 11.5, 2 ], d4: [ 12.5, 2 ], d5: [ 13.5, 2 ],
      x1: [ 0, 3 ], x2: [ 1, 3 ], x3: [ 2, 3 ]
    }, result)
  end

  # B has no children, so the comparison between A's and C's grandchildren
  # runs through B along a thread; without it c1 would land on a3. Blocks of
  # width 2 and 1 alternate on the bottom row, and B ends up midway between
  # its siblings' blocks after the shift is spread.
  test "subtrees either side of a leaf still keep their distance" do
    result = layout(
      g: [ [ :GF, :GM ], [ :A, :B, :C ] ],
      a: [ [ :A, :SA ], [ :a1, :a2, :a3 ] ],
      a1: [ [ :a1, :w1 ], [] ],
      a3: [ [ :a3, :w3 ], [] ],
      c: [ [ :C, :SC ], [ :c1, :c2, :c3 ] ],
      c1: [ [ :c1, :v1 ], [] ],
      c3: [ [ :c3, :v3 ], [] ]
    )

    assert_positions({
      GF: [ 3.5, 0 ], GM: [ 4.5, 0 ],
      A: [ 1, 1 ], SA: [ 2, 1 ], B: [ 4.5, 1 ], C: [ 7, 1 ], SC: [ 8, 1 ],
      a1: [ 0, 2 ], w1: [ 1, 2 ], a2: [ 2, 2 ], a3: [ 3, 2 ], w3: [ 4, 2 ],
      c1: [ 6, 2 ], v1: [ 7, 2 ], c2: [ 8, 2 ], c3: [ 9, 2 ], v3: [ 10, 2 ]
    }, result)
  end

  # L's line runs four rows deep on the left while P's family is wide at the
  # bottom right; the left contour's accumulated offset has to carry down to
  # the row where they meet, or y1 drifts into the m row. An ancestor line
  # with no loaded siblings steps half a slot right per generation.
  test "a deep left line and a wide right family meet without touching" do
    result = layout(
      gg: [ [ :GGF, :GGM ], [ :L, :P ] ],
      l: [ [ :L, :SL ], [ :l1 ] ],
      l1: [ [ :l1, :u1 ], [ :l2 ] ],
      l2: [ [ :l2, :u2 ], [ :m1, :m2, :m3, :m4 ] ],
      p: [ [ :P, :SP ], [ :A, :C ] ],
      a: [ [ :A, :SA ], [ :a1 ] ],
      c: [ [ :C, :SC ], [ :c1 ] ],
      c1: [ [ :c1, :v1 ], [ :y1, :y2, :y3 ] ]
    )

    assert_positions({
      GGF: [ 1.5, 0 ], GGM: [ 2.5, 0 ],
      L: [ 0, 1 ], SL: [ 1, 1 ], P: [ 4, 1 ], SP: [ 5, 1 ],
      l1: [ 0.5, 2 ], u1: [ 1.5, 2 ], A: [ 3.5, 2 ], SA: [ 4.5, 2 ], C: [ 5.5, 2 ], SC: [ 6.5, 2 ],
      l2: [ 1, 3 ], u2: [ 2, 3 ], a1: [ 4, 3 ], c1: [ 6, 3 ], v1: [ 7, 3 ],
      m1: [ 0, 4 ], m2: [ 1, 4 ], m3: [ 2, 4 ], m4: [ 3, 4 ], y1: [ 5.5, 4 ], y2: [ 6.5, 4 ], y3: [ 7.5, 4 ]
    }, result)
  end

  test "a remarried person sits between their spouses, first marriage on the left" do
    result = layout(
      first: [ [ :P, :S1 ], [ :c1 ] ],
      second: [ [ :P, :S2 ], [ :c2 ] ]
    )

    assert_positions({
      S1: [ 0, 0 ], P: [ 1, 0 ], S2: [ 2, 0 ],
      c1: [ 0.5, 1 ], c2: [ 1.5, 1 ]
    }, result)
  end

  test "children of the second marriage sit under the second marriage, not the first spouse" do
    result = layout(
      first: [ [ :P, :S1 ], [] ],
      second: [ [ :P, :S2 ], [ :C, :D ] ]
    )

    assert_positions({ S1: [ 0, 0 ], P: [ 1, 0 ], S2: [ 2, 0 ], C: [ 1, 1 ], D: [ 2, 1 ] }, result)
  end

  # Three children by the first marriage, one by the second: the block is
  # centred for the first brood, and the second's drop (at 2) lands at the
  # left edge of its own child rather than over the first marriage's.
  test "uneven broods keep each marriage's drop within its own children" do
    result = layout(
      first: [ [ :P, :S1 ], [ :a, :b, :c ] ],
      second: [ [ :P, :S2 ], [ :d ] ]
    )

    assert_positions({
      S1: [ 0.5, 0 ], P: [ 1.5, 0 ], S2: [ 2.5, 0 ],
      a: [ 0, 1 ], b: [ 1, 1 ], c: [ 2, 1 ], d: [ 3, 1 ]
    }, result)
  end

  test "a parentless unit whose only child hangs elsewhere is skipped" do
    result = layout(
      orphans: [ [], [ :C ] ], parents: [ [ :F, :M ], [ :C ] ],
      individual_ids: %i[C F M]
    )

    assert_positions({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 1 ] }, result)
  end

  test "a wife's second husband sits to her right" do
    result = layout(
      first: [ [ :H1, :W ], [ :c1 ] ],
      second: [ [ :H2, :W ], [ :c2 ] ]
    )

    assert_positions({
      H1: [ 0, 0 ], W: [ 1, 0 ], H2: [ 2, 0 ],
      c1: [ 0.5, 1 ], c2: [ 1.5, 1 ]
    }, result)
  end

  test "when both spouses have loaded parents, every grandparent shares the top row and the wife's parents pack on her side" do
    result = layout(
      fathers: [ [ :FF, :FM ], [ :F ] ],
      mothers: [ [ :MF, :MM ], [ :M ] ],
      own: [ [ :F, :M ], [ :C ] ],
      individual_ids: %i[C F M FF FM MF MM]
    )

    assert_positions({
      FF: [ 0, 0 ], FM: [ 1, 0 ], MF: [ 2, 0 ], MM: [ 3, 0 ],
      F: [ 0.5, 1 ], M: [ 1.5, 1 ],
      C: [ 1, 2 ]
    }, result)
  end

  # Same people, but the loaded set starts with the wife's parents, so the
  # husband's family is placed second and has to go to the left of them.
  test "the side a related tree packs on follows its link, not input order" do
    result = layout(
      fathers: [ [ :FF, :FM ], [ :F ] ],
      mothers: [ [ :MF, :MM ], [ :M ] ],
      own: [ [ :F, :M ], [ :C ] ],
      individual_ids: %i[MF MM M F C FF FM]
    )

    assert_positions({
      FF: [ 0, 0 ], FM: [ 1, 0 ], MF: [ 2, 0 ], MM: [ 3, 0 ],
      F: [ 0.5, 1 ], M: [ 1.5, 1 ],
      C: [ 1, 2 ]
    }, result)
  end

  # The husband's two younger brothers make the row to the wife's right
  # busy; the clear spot on the left is nearer, but her parents belong on
  # her side, so the layout goes right regardless.
  test "in-laws pack on their own child's side even when the other side is nearer" do
    result = layout(
      fathers: [ [ :FF, :FM ], [ :F, :FB1, :FB2 ] ],
      own: [ [ :F, :M ], [] ],
      mothers: [ [ :MF, :MM ], [ :M, :MS ] ],
      individual_ids: %i[F M FF FM FB1 FB2 MF MM MS]
    )

    assert_positions({
      FF: [ 1, 0 ], FM: [ 2, 0 ], MF: [ 3.5, 0 ], MM: [ 4.5, 0 ],
      F: [ 0, 1 ], M: [ 1, 1 ], FB1: [ 2, 1 ], FB2: [ 3, 1 ], MS: [ 4, 1 ]
    }, result)
  end

  test "the wife's siblings land beside her" do
    result = layout(
      fathers: [ [ :FF, :FM ], [ :F ] ],
      mothers: [ [ :MF, :MM ], [ :M, :MS ] ],
      own: [ [ :F, :M ], [ :C ] ],
      individual_ids: %i[C F M MS FF FM MF MM]
    )

    assert_positions({
      FF: [ 0, 0 ], FM: [ 1, 0 ], MF: [ 2, 0 ], MM: [ 3, 0 ],
      F: [ 0.5, 1 ], M: [ 1.5, 1 ], MS: [ 2.5, 1 ],
      C: [ 1, 2 ]
    }, result)
  end

  test "a husband with loaded parents on the mother's side packs them on his side" do
    # The wife is listed first in her unit, so she anchors the block and the
    # husband is the cross-linked spouse sitting on the right.
    result = layout(
      hers: [ [ :WF, :WM ], [ :W ] ],
      his: [ [ :HF, :HM ], [ :H ] ],
      own: [ [ :W, :H ], [ :C ] ],
      individual_ids: %i[C W H WF WM HF HM]
    )

    assert_positions({
      WF: [ 0, 0 ], WM: [ 1, 0 ], HF: [ 2, 0 ], HM: [ 3, 0 ],
      W: [ 0.5, 1 ], H: [ 1.5, 1 ],
      C: [ 1, 2 ]
    }, result)
  end

  test "step-parents sharing no row with the siblings centre over their child" do
    result = layout(
      sibs: [ [], [ :C, :D ] ], step: [ [ :SF, :SM ], [ :C ] ],
      individual_ids: %i[C D SF SM]
    )

    assert_positions({ SF: [ 0, 0 ], SM: [ 1, 0 ], C: [ 0.5, 1 ], D: [ 1.5, 1 ] }, result)
  end

  test "an unrelated person is parked to the right with an empty slot, on the top row" do
    result = layout(u: [ [ :A, :B ], [] ], individual_ids: %i[A B X])

    assert_positions({ A: [ 0, 0 ], B: [ 1, 0 ], X: [ 3, 0 ] }, result)
    assert_equal 4, result.width
  end

  test "unrelated families each start on the top row" do
    result = layout(
      one: [ [ :F, :M ], [ :C ] ], two: [ [ :X, :Y ], [] ],
      individual_ids: %i[C F M X Y]
    )

    assert_positions({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 1 ], X: [ 3, 0 ], Y: [ 4, 0 ] }, result)
  end

  test "a parked sibling group with no parents still starts on the top row" do
    result = layout(
      one: [ [ :F, :M ], [ :C ] ], orphans: [ [], [ :A, :B ] ],
      individual_ids: %i[C F M A B]
    )

    assert_positions({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 1 ], A: [ 3, 0 ], B: [ 4, 0 ] }, result)
  end

  test "a child listed in two families of the same depth is drawn once, under the first" do
    result = layout(
      birth: [ [ :F, :M ], [ :C ] ], step: [ [ :SF, :SM ], [ :C ] ],
      individual_ids: %i[C F M SF SM]
    )

    assert_positions({ F: [ 0, 0 ], M: [ 1, 0 ], SF: [ 2, 0 ], SM: [ 3, 0 ], C: [ 0.5, 1 ] }, result)
  end

  test "a grandchild also recorded in the grandparents' family hangs under the parents" do
    result = layout(g: [ [ :G1, :G2 ], [ :P, :C ] ], p: [ [ :P, :S ], [ :C ] ])

    assert_positions({ G1: [ 0, 0 ], G2: [ 1, 0 ], P: [ 0.5, 1 ], S: [ 1.5, 1 ], C: [ 1, 2 ] }, result)
  end

  test "a child in a parentless unit and in a unit with parents hangs under the parents" do
    result = layout(
      orphans: [ [], [ :C, :D ] ], parents: [ [ :F, :M ], [ :C ] ],
      individual_ids: %i[C D F M]
    )

    assert_positions({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 1 ], D: [ 1.5, 1 ] }, result)
  end

  test "ids in units but not in the loaded set are ignored" do
    result = layout(u: [ [ :F, :M ], [ :C, :ghost ] ], individual_ids: %i[F M C])

    assert_positions({ F: [ 0, 0 ], M: [ 1, 0 ], C: [ 0.5, 1 ] }, result)
  end

  test "someone recorded as their own ancestor still gets a place" do
    # W is loaded first and hangs off the loop, so the walk enters the cycle
    # from outside: the edge that closes it (B's parent) is the one cut.
    result = layout(
      up: [ [ :A ], [ :B ] ], down: [ [ :B ], [ :A ] ], side: [ [ :A ], [ :W ] ],
      individual_ids: %i[W A B]
    )

    assert_positions({ B: [ 0, 0 ], A: [ 0, 1 ], W: [ 0, 2 ] }, result)
  end

  test "the sketch draws one line per generation" do
    result = layout(u: [ [ :F, :M ], [ :C ] ])

    assert_equal [ "F   M", "  C" ], result.sketch.lines.map(&:rstrip)
  end

  # Seeded random forests: a few root couples with children to a bounded
  # depth, men marrying women out of *another* root's tree (a cross-link), a
  # parentless sibling group or two, a few hermits. Generations are
  # consistent by construction, so every parent-child pair must land exactly
  # one row apart, across trees too.
  class RandomForest
    MAX_DEPTH = 3

    attr_reader :units, :ids, :cross_linked

    def initialize(seed)
      @rng = Random.new(seed)
      @units = []
      @ids = []
      @cross_linked = []
      @single_women = Hash.new { |h, k| h[k] = [] }
      @rng.rand(1..3).times { |root| household(person, person, 0, root) }
      @rng.rand(0..2).times { unit([], Array.new(@rng.rand(2..4)) { person }) }
      @rng.rand(0..2).times { person }
    end

    private

    def person
      @ids << @ids.size
      @ids.last
    end

    def unit(parents, children)
      @units << FamilyTree::Layout::Unit.new(id: @units.size, parent_ids: parents, child_ids: children)
    end

    def household(husband, wife, depth, root)
      children = Array.new(@rng.rand(0..3)) { person }
      unit([ husband, wife ], children)
      children.each { |child| grow(child, depth + 1, root) }
    end

    def grow(child, depth, root)
      return if depth >= MAX_DEPTH
      case @rng.rand(3)
      when 0 then household(child, bride(depth, root), depth, root)
      when 1 then @single_women[depth] << [ root, child ]
      end
    end

    # A bride from another root's tree, same generation, becomes a cross-link:
    # the groom has parents, so his side anchors the couple.
    def bride(depth, root)
      candidates = @single_women[depth].reject { |home, _| home == root }
      return person if candidates.empty?
      pick = candidates.sample(random: @rng)
      @single_women[depth].delete(pick)
      @cross_linked << pick.last
      pick.last
    end
  end

  test "random forests keep every invariant" do
    200.times do |seed|
      forest = RandomForest.new(seed)
      result = FamilyTree::Layout.new(individual_ids: forest.ids, units: forest.units)
      positions = result.positions
      at = ->(id) { positions.fetch(id) }
      message = "seed #{seed}\n#{result.sketch}"

      assert_equal forest.ids.sort, positions.keys.sort, message

      positions.values.group_by(&:generation).each_value do |row|
        row.map(&:x).sort.each_cons(2) do |left, right|
          assert_operator right - left, :>=, 1 - 1e-9, "cards overlap: #{message}"
        end
      end

      forest.units.each do |unit|
        unit.parent_ids.product(unit.child_ids).each do |parent, child|
          assert_equal at.(parent).generation + 1, at.(child).generation,
            "#{child} is not one row below #{parent}: #{message}"
        end

        if unit.parent_ids.size == 2
          husband, wife = unit.parent_ids.map(&at)
          assert_equal husband.generation, wife.generation, message
          assert_in_delta husband.x + 1, wife.x, 1e-9, "spouses apart: #{message}"
        end

        tree_children = unit.child_ids - forest.cross_linked
        xs = tree_children.map { |id| at.(id).x }
        assert_equal xs, xs.sort, "birth order broken: #{message}"

        if unit.parent_ids.size == 2 && tree_children.any?
          centre = unit.parent_ids.sum { |id| at.(id).x } / 2.0
          assert_in_delta (xs.first + xs.last) / 2.0, centre, 1e-9, "parents off centre: #{message}"
        end
      end

      assert_in_delta 0, positions.values.map(&:x).min, 1e-9, message
      assert_equal 0, positions.values.map(&:generation).min, message

      again = FamilyTree::Layout.new(individual_ids: forest.ids, units: forest.units)
      assert_equal positions, again.positions, "layout is not deterministic: #{message}"
    end
  end
end
