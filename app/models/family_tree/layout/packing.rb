module FamilyTree
  class Layout
    # Places the laid-out trees side by side. The tree holding the first
    # individual goes first; trees joined to it by links follow breadth-first,
    # each dropped where its link lines up (the child under the unit's
    # midpoint) and nudged to whichever clear side is nearer. Rows are
    # reconciled through the same links so generations stay aligned across
    # trees. Whatever is left over — people with no loaded relatives — is
    # parked to the right with an empty slot, top row aligned.
    #
    # ponytail: per-row extents only, so a tree lands outside everything
    # already placed in every row it shares; it never tucks into a gap. Two
    # trees linked twice align on the first link found.
    class Packing
      def initialize(forest)
        @forest = forest
        @extents = {}
        @placed = Set.new.compare_by_identity
      end

      def call
        return unless (first = @forest.first_tree)

        queue = [ [ first, nil ] ]
        until @placed.size == @forest.trees.size
          queue << [ largest_unplaced, nil ] if queue.empty?
          tree, link = queue.shift
          next if @placed.include?(tree)

          place(tree, link)
          queue.concat(neighbours(tree))
        end
      end

      private

      def place(tree, link)
        rows = tree.blocks.reject(&:phantom?).group_by(&:depth)
        # A phantom whose children all hang elsewhere has nothing to place.
        return @placed << tree if rows.empty?

        row_shift, desired, side = link ? alignment(tree, link) : [ top_row - rows.keys.min, nil, 0 ]
        column_shift = clearing(rows, row_shift, desired, side)

        tree.blocks.each do |block|
          block.depth += row_shift
          block.x += column_shift
        end
        rows.each_value do |blocks|
          extent = @extents[blocks.first.depth] ||= [ Float::INFINITY, -Float::INFINITY ]
          extent[0] = [ extent[0], leftmost(blocks) ].min
          extent[1] = [ extent[1], rightmost(blocks) ].max
        end
        @placed << tree
      end

      # Row and column offsets that line the new tree's end of the link up with
      # the placed end (a child one row below its unit, centred under it), and
      # the side to clear towards: the one the child sits on within its block,
      # so each spouse's family goes out past that spouse.
      def alignment(tree, link)
        child = @forest.block_of(link.child)
        unit = @forest.block_of_unit(link.unit)
        side = child.seat_of(link.child) <=> 0
        if child.tree.equal?(tree)
          [ unit.depth + 1 - child.depth, unit.midpoint_of(link.unit) - child.x_of(link.child), -side ]
        else
          [ child.depth - 1 - unit.depth, child.x_of(link.child) - unit.midpoint_of(link.unit), side ]
        end
      end

      # The column offset nearest to `desired` on the given side (nearest on
      # either side when the link child is centred in its block) at which no
      # shared row comes closer than a slot, plus an empty slot for unrelated
      # trees. Nothing placed yet, or no shared rows: `desired` itself.
      def clearing(rows, row_shift, desired, side)
        return 0.0 if @extents.empty?
        return right_of_everything(rows) unless desired

        right = -Float::INFINITY
        left = Float::INFINITY
        rows.each do |depth, blocks|
          next unless (placed_min, placed_max = @extents[depth + row_shift])

          right = [ right, placed_max - leftmost(blocks) + 1 ].max
          left = [ left, placed_min - rightmost(blocks) - 1 ].min
        end
        return desired if right.infinite?

        candidates = [ [ desired, right ].max, [ desired, left ].min ]
        return candidates.first if side.positive?
        return candidates.last if side.negative?

        candidates.min_by { |offset| (offset - desired).abs }
      end

      def right_of_everything(rows)
        @extents.values.map(&:last).max - leftmost(rows.values.flatten) + 2
      end

      def leftmost(blocks) = blocks.map { |block| block.x - (block.width - 1) / 2.0 }.min
      def rightmost(blocks) = blocks.map { |block| block.x + (block.width - 1) / 2.0 }.max

      def top_row = @extents.keys.min || 0

      def largest_unplaced
        @forest.trees.each_with_index.reject { |tree, _| @placed.include?(tree) }
          .max_by { |tree, index| [ tree.blocks.sum(&:width), -index ] }.first
      end

      # Unplaced trees reachable from this one, in left-to-right order of the
      # link's end inside this tree, so the first link found is the nearest.
      def neighbours(tree)
        @forest.links.filter_map do |link|
          child = @forest.block_of(link.child)
          unit = @forest.block_of_unit(link.unit)
          here, there = child.tree.equal?(tree) ? [ child, unit ] : [ unit, child ]
          next if !here.tree.equal?(tree) || @placed.include?(there.tree)

          anchor_x = here.equal?(child) ? child.x_of(link.child) : unit.midpoint_of(link.unit)
          [ anchor_x, [ there.tree, link ] ]
        end.sort_by(&:first).map(&:last)
      end
    end
  end
end
