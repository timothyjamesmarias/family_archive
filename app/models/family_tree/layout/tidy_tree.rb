module FamilyTree
  class Layout
    # Buchheim, Jünger & Leipert (2002), "Improving Walker's Algorithm to Run
    # in Linear Time", ported from d3-hierarchy's tree.js. Walks the tree once
    # bottom-up placing each node relative to its left sibling and pushing
    # whole subtrees apart where their contours would touch, then once
    # top-down to turn the accumulated shifts into coordinates.
    #
    # Nodes are Blocks: `children` and `width` in, `x` out (root at 0).
    # Siblings sit in adjacent slots; anything else gets one empty slot.
    class TidyTree
      # The paper's names, spelled out: z → prelim, m → mod, c → change,
      # s → shift, t → thread, a → ancestor, A → default_ancestor.
      Node = Struct.new(:block, :parent, :children, :index, :prelim, :mod, :change, :shift, :thread, :ancestor, :default_ancestor) do
        def initialize(block, parent, children, index)
          super(block, parent, children, index, 0.0, 0.0, 0.0, 0.0, nil, self, nil)
        end
      end

      def initialize(root)
        @root = wrap(root, nil, 0)
        # A stand-in parent gives the root a sibling list like every other node.
        @root.parent = Node.new(nil, nil, [ @root ], 0)
      end

      def call
        each_after(@root) { |node| first_walk(node) }
        @root.parent.mod = -@root.prelim
        each_before(@root) { |node| second_walk(node) }
      end

      private

      def wrap(block, parent, index)
        node = Node.new(block, parent, [], index)
        node.children = block.children.each_with_index.map { |child, i| wrap(child, node, i) }
        node
      end

      def each_after(node, &walk)
        node.children.each { |child| each_after(child, &walk) }
        walk.(node)
      end

      def each_before(node, &walk)
        walk.(node)
        node.children.each { |child| each_before(child, &walk) }
      end

      def separation(a, b)
        (a.block.width + b.block.width) / 2.0 + (a.parent.equal?(b.parent) ? 0 : 1)
      end

      def first_walk(v)
        siblings = v.parent.children
        w = v.index.positive? ? siblings[v.index - 1] : nil
        if v.children.any?
          execute_shifts(v)
          midpoint = (anchor_x(v.children.first) + anchor_x(v.children.last)) / 2.0
          if w
            v.prelim = w.prelim + separation(v, w)
            v.mod = v.prelim - midpoint
          else
            v.prelim = midpoint
          end
        elsif w
          v.prelim = w.prelim + separation(v, w)
        end
        v.parent.default_ancestor = apportion(v, w, v.parent.default_ancestor || siblings.first)
      end

      def second_walk(v)
        v.block.x = v.prelim + v.parent.mod
        v.mod += v.parent.mod
      end

      # A parent is centred over its children's own cards, not their blocks,
      # so a married child hangs under the marriage and the in-law beside them.
      def anchor_x(node) = node.prelim + node.block.anchor_offset

      # Compare the right contour of everything left of v with the left
      # contour of v, level by level, and shift v's subtree right wherever the
      # two would come too close. Threads stitch contours together so each
      # level is visited once.
      def apportion(v, w, ancestor)
        return ancestor unless w

        vip = vop = v
        vim = w
        vom = vip.parent.children.first
        sip = vip.mod
        sop = vop.mod
        sim = vim.mod
        som = vom.mod

        loop do
          vim = next_right(vim)
          vip = next_left(vip)
          break unless vim && vip

          vom = next_left(vom)
          vop = next_right(vop)
          vop.ancestor = v
          shift = vim.prelim + sim - vip.prelim - sip + separation(vim, vip)
          if shift.positive?
            move_subtree(next_ancestor(vim, v, ancestor), v, shift)
            sip += shift
            sop += shift
          end
          sim += vim.mod
          sip += vip.mod
          som += vom.mod
          sop += vop.mod
        end

        if vim && next_right(vop).nil?
          vop.thread = vim
          vop.mod += sim - sop
        end
        if vip && next_left(vom).nil?
          vom.thread = vip
          vom.mod += sip - som
          ancestor = v
        end
        ancestor
      end

      def next_left(v) = v.children.first || v.thread
      def next_right(v) = v.children.last || v.thread

      def next_ancestor(vim, v, ancestor)
        vim.ancestor.parent.equal?(v.parent) ? vim.ancestor : ancestor
      end

      # Spread a shift evenly over the siblings between wm and wp; executed
      # lazily by execute_shifts when their parent is visited.
      def move_subtree(wm, wp, shift)
        change = shift / (wp.index - wm.index)
        wp.change -= change
        wp.shift += shift
        wm.change += change
        wp.prelim += shift
        wp.mod += shift
      end

      def execute_shifts(v)
        shift = 0.0
        change = 0.0
        v.children.reverse_each do |w|
          w.prelim += shift
          w.mod += shift
          change += w.change
          shift += w.shift + change
        end
      end
    end
  end
end
