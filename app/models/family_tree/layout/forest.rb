module FamilyTree
  class Layout
    # Turns people and units into the forest the tidy tree lays out.
    #
    # People connected by marriage form one *block* (a couple is a block of
    # width 2). Each block hangs under the unit its *anchor* is a child of —
    # the first member with loaded parents, scanning the block's units and
    # their parents in input order. Every other parent→child relation is a
    # *link*: it does not shape the tree, but Packing uses it to align
    # generations and pull related trees together.
    class Forest
      # A mutable graph node, compared by identity.
      class Block
        attr_accessor :members, :units, :anchor, :parent, :children, :groups, :depth, :x, :tree

        def initialize(members, units = [])
          @members = members
          @units = units
          @children = []
          @groups = []
          @depth = 0
          @x = 0.0
        end

        def width = members.size
        def phantom? = members.empty?

        # Offset of a member from the block's centre, in slots.
        def seat_of(id) = members.index(id) - (members.size - 1) / 2.0
        def x_of(id) = x + seat_of(id)
        def anchor_offset = anchor ? seat_of(anchor) : 0.0

        # Where a unit's drop line starts: between its parents, or the
        # phantom's own position for a unit with no loaded parents.
        def midpoint_of(unit)
          return x if unit.parent_ids.empty?
          unit.parent_ids.sum { |id| x_of(id) } / unit.parent_ids.size.to_f
        end
      end

      Tree = Struct.new(:root, :blocks)
      Link = Data.define(:child, :unit)

      attr_reader :blocks, :trees, :links

      def initialize(individual_ids, units)
        @ids = individual_ids.uniq
        @units = prune(units)
        @units_of = @units.each_with_object(Hash.new { |index, id| index[id] = [] }) do |unit, index|
          unit.parent_ids.each { |id| index[id] << unit }
        end
        @parent_unit = deepest_parent_unit
        @block_of = {}
        @unit_block = {}
        @blocks = marriage_blocks + phantom_blocks
        attach_units
        hang_blocks
        cut_cycles
        @trees = grow_trees
        @links = non_tree_edges
      end

      def block_of(id) = @block_of.fetch(id)
      def block_of_unit(unit) = @unit_block.fetch(unit)
      def first_tree = @ids.empty? ? nil : block_of(@ids.first).tree

      private

      # Ids outside the loaded set are dropped, and a child listed twice in
      # one unit is one child: either would otherwise be laid out twice.
      def prune(units)
        loaded = @ids.to_set
        units.filter_map do |unit|
          kept = Unit.new(id: unit.id,
            parent_ids: unit.parent_ids.select { |id| loaded.include?(id) },
            child_ids: unit.child_ids.select { |id| loaded.include?(id) }.uniq)
          kept if kept.parent_ids.any? || kept.child_ids.any?
        end
      end

      # A child of two units hangs under the one whose parents sit deepest, so
      # a grandchild also recorded in the grandparents' family is drawn under
      # the parents, and a unit with loaded parents beats a parentless one.
      # Ties go to input order.
      def deepest_parent_unit
        listing = @units.each_with_object(Hash.new { |index, id| index[id] = [] }) do |unit, index|
          unit.child_ids.each { |child| index[child] << unit }
        end
        depth = Hash.new do |memo, id|
          memo[id] = 0 # a revisit while still descending reads 0: cycles end here
          memo[id] = 1 + (listing.fetch(id, []).flat_map(&:parent_ids).map { |parent| memo[parent] }.max || -1)
        end
        listing.to_h do |child, units|
          deepest = units.min_by.with_index { |unit, index| [ -(unit.parent_ids.map { |id| depth[id] }.max || -1), index ] }
          [ child, deepest ]
        end
      end

      # Walk co-parent edges from the first parent of each unit (the husband,
      # by the Builder's convention); whoever is left unseated is a singleton.
      # Blocks come back in individual_ids order: Packing breaks ties between
      # unlinked trees by it.
      def marriage_blocks
        starts = @units.filter_map { |unit| unit.parent_ids.first } + @ids
        starts.each do |start|
          next if @block_of.key?(start)
          block = Block.new(linearise(start))
          block.members.each { |id| @block_of[id] = block }
        end
        @ids.map { |id| @block_of[id] }.uniq
      end

      # Seat each newly met spouse beside the person they marry: on the right,
      # or, when that person is at the left end, after turning the row around
      # so the spouse still lands beside them. A remarried person ends up
      # between their spouses, first marriage on the left: S1 P S2.
      # ponytail: a third spouse is appended on the right and that marriage
      # line passes behind a card. Fine until the data shows otherwise.
      def linearise(start)
        order = [ start ]
        queue = [ start ]
        until queue.empty?
          person = queue.shift
          @units_of.fetch(person, []).flat_map(&:parent_ids).each do |spouse|
            next if order.include?(spouse)
            order.reverse! if order.first == person && order.size > 1
            order << spouse
            queue << spouse
          end
        end
        order
      end

      # A unit with loaded children but no loaded parents still needs a node
      # above the children so they hang together. Width 0, never rendered.
      def phantom_blocks
        @units.select { |unit| unit.parent_ids.empty? }.map do |unit|
          @unit_block[unit] = Block.new([], [ unit ])
        end
      end

      def attach_units
        @units.reject { |unit| unit.parent_ids.empty? }.each do |unit|
          block = block_of(unit.parent_ids.first)
          @unit_block[unit] = block
          block.units << unit
        end
      end

      def hang_blocks
        @blocks.each do |block|
          next if block.phantom?
          block.anchor = (block.units.flat_map(&:parent_ids) + block.members).uniq.find { |id| @parent_unit[id] }
          block.parent = block_of_unit(@parent_unit[block.anchor]) if block.anchor
        end
      end

      # Someone recorded as their own ancestor would make the parent chain
      # loop. Walk up from every block once; the edge that closes a loop is cut
      # and that block becomes a root (its parent link survives as a long edge).
      def cut_cycles
        settled = Set.new
        @blocks.each do |block|
          path = []
          current = block
          while current && !settled.include?(current)
            if path.include?(current)
              path.last.parent = nil
              break
            end
            path << current
            current = current.parent
          end
          settled.merge(path)
        end
      end

      # Children hang under their unit; units are ordered left to right by
      # where they sit inside the block (every x is still 0 here, so
      # midpoint_of is the seat), so a remarried person's first marriage
      # keeps its children on the left. Groups remember which seat each run
      # of children belongs under, for the tidy tree to centre them there.
      def grow_trees
        @blocks.each do |block|
          block.units = block.units.sort_by.with_index { |unit, index| [ block.midpoint_of(unit), index ] }
          by_unit = block.units.filter_map do |unit|
            children = unit.child_ids.select { |child| tree_edge?(child, unit) }.map { |child| block_of(child) }
            [ block.midpoint_of(unit), children ] if children.any?
          end
          # Two units at one seat (a lone parent's two broods) are one group.
          block.groups = by_unit.chunk_while { |a, b| a.first == b.first }.map { |run| [ run.first.first, run.flat_map(&:last) ] }
          block.children = block.groups.flat_map(&:last)
        end

        @blocks.select { |block| block.parent.nil? }.map do |root|
          tree = Tree.new(root, [])
          adopt(root, tree, 0)
          tree
        end
      end

      def tree_edge?(child, unit)
        block = block_of(child)
        block.anchor == child && @parent_unit[child] == unit && block.parent.equal?(block_of_unit(unit))
      end

      def adopt(block, tree, depth)
        block.tree = tree
        block.depth = depth
        tree.blocks << block
        block.children.each { |child| adopt(child, tree, depth + 1) }
      end

      def non_tree_edges
        @units.flat_map do |unit|
          unit.child_ids.reject { |child| tree_edge?(child, unit) }.map { |child| Link.new(child:, unit:) }
        end
      end
    end
  end
end
