module FamilyTree
  # Line segments for a chart, in the layout's units: x in slots, y in rows,
  # card centres at integer rows. Cards paint over the lines, so a marriage
  # line runs centre to centre and a stub ends at the child's centre. The view
  # scales to pixels and styles by `kind`.
  class Edges
    Segment = Data.define(:kind, :x1, :y1, :x2, :y2)

    # A sibling bus runs this far above its children's row; buses of different
    # units that would overlap on one row step down a lane each.
    BUS_ABOVE = 0.4
    LANE = 0.1

    Bus = Data.define(:unit, :row, :x1, :x2, :child_xs)

    def initialize(positions:, units:)
      @positions = positions
      @units = units
    end

    def segments
      @segments ||= begin
        offsets = lane_offsets
        @units.flat_map do |unit|
          marriage(unit) +
            buses.select { |bus| bus.unit == unit }.flat_map { |bus| bus_segments(bus, offsets.fetch(bus)) } +
            links(unit)
        end
      end
    end

    private

    def at(id) = @positions.fetch(id)
    def parents(unit) = unit.parent_ids.select { |id| @positions.key?(id) }
    def children(unit) = unit.child_ids.select { |id| @positions.key?(id) }

    # Phantom units (no loaded parents) sit one row above their children.
    def parent_row(unit)
      return at(parents(unit).first).generation if parents(unit).any?
      children(unit).map { |id| at(id).generation }.min.to_i - 1
    end

    def midpoint(unit)
      parents(unit).sum { |id| at(id).x } / parents(unit).size.to_f
    end

    def marriage(unit)
      return [] if parents(unit).size < 2
      row = parent_row(unit)
      [ Segment.new(kind: :marriage, x1: at(parents(unit).first).x, y1: row, x2: at(parents(unit).last).x, y2: row) ]
    end

    # One bus per row of children below the parents; the drop joins it, so the
    # bus stretches to the midpoint when the children all sit to one side.
    def buses
      @buses ||= @units.flat_map do |unit|
        below = children(unit).select { |id| at(id).generation > parent_row(unit) }
        below.group_by { |id| at(id).generation }.map do |row, ids|
          xs = ids.map { |id| at(id).x }
          span = parents(unit).any? ? xs + [ midpoint(unit) ] : xs
          Bus.new(unit:, row:, x1: span.min, x2: span.max, child_xs: xs)
        end
      end
    end

    def bus_segments(bus, offset)
      y = bus.row - BUS_ABOVE + offset
      drop = parents(bus.unit).any? ? [ Segment.new(kind: :drop, x1: midpoint(bus.unit), y1: parent_row(bus.unit), x2: midpoint(bus.unit), y2: y) ] : []
      line = bus.x1 < bus.x2 ? [ Segment.new(kind: :bus, x1: bus.x1, y1: y, x2: bus.x2, y2: y) ] : []
      stubs = bus.child_xs.map { |x| Segment.new(kind: :stub, x1: x, y1: y, x2: x, y2: bus.row) }
      drop + line + stubs
    end

    # Greedy interval colouring per row: each bus takes the lowest lane whose
    # previous bus ended before this one starts.
    def lane_offsets
      buses.group_by(&:row).values.flat_map do |row|
        ends = []
        row.sort_by(&:x1).map do |bus|
          lane = ends.index { |x2| x2 < bus.x1 } || ends.size
          ends[lane] = bus.x2
          [ bus, lane * LANE ]
        end
      end.to_h
    end

    # A child on or above the parents' row (data the tree model cannot place)
    # gets a straight line rather than bus-and-stub geometry.
    def links(unit)
      return [] if parents(unit).empty?
      row = parent_row(unit)
      children(unit).reject { |id| at(id).generation > row }.map do |id|
        Segment.new(kind: :link, x1: midpoint(unit), y1: row, x2: at(id).x, y2: at(id).generation)
      end
    end
  end
end
