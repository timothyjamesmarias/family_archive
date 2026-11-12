module FamilyTree
  # The chart's lines, in pixels, as the design draws them: a couple is joined
  # by a bracket below their cards, the drop falls from its middle to a bus
  # above the children, and a stub rises to each child. The view only has to
  # draw segments and style them by `kind`.
  class Edges
    Segment = Data.define(:kind, :x1, :y1, :x2, :y2)
    Bus = Data.define(:unit, :generation, :x1, :x2, :child_xs)

    def initialize(positions:, units:)
      @positions = positions
      @units = units
    end

    def segments
      @segments ||= begin
        lanes = lane_of
        @units.flat_map do |unit|
          bracket(unit) +
            buses.select { |bus| bus.unit == unit }.flat_map { |bus| bus_segments(bus, lanes.fetch(bus)) } +
            links(unit)
        end
      end
    end

    private

    def at(id) = @positions.fetch(id)
    def parents(unit) = unit.parent_ids.select { |id| @positions.key?(id) }
    def children(unit) = unit.child_ids.select { |id| @positions.key?(id) }

    def parent_generation(unit) = at(parents(unit).first).generation

    def midpoint(unit)
      parents(unit).sum { |id| Metrics.centre(at(id).x) } / parents(unit).size.to_f
    end

    # Where the drop starts: the bracket under a couple, or straight off the
    # bottom of a lone parent's card.
    def drop_top(unit)
      Metrics.bottom(parent_generation(unit)) + (parents(unit).size > 1 ? Metrics::BRACKET : 0)
    end

    def bracket(unit)
      return [] if parents(unit).size < 2
      bottom = Metrics.bottom(parent_generation(unit))
      first, last = parents(unit).values_at(0, -1).map { |id| Metrics.centre(at(id).x) }
      y = drop_top(unit)
      [
        Segment.new(kind: :marriage, x1: first, y1: bottom, x2: first, y2: y),
        Segment.new(kind: :marriage, x1: first, y1: y, x2: last, y2: y),
        Segment.new(kind: :marriage, x1: last, y1: y, x2: last, y2: bottom)
      ]
    end

    # One bus per row of children below the parents (a parentless unit's
    # children are all below). The drop joins it, so the bus stretches to the
    # midpoint when every child sits to one side.
    def buses
      @buses ||= @units.flat_map do |unit|
        below = parents(unit).any? ? children(unit).select { |id| at(id).generation > parent_generation(unit) } : children(unit)
        below.group_by { |id| at(id).generation }.map do |generation, ids|
          xs = ids.map { |id| Metrics.centre(at(id).x) }
          span = parents(unit).any? ? xs + [ midpoint(unit) ] : xs
          Bus.new(unit:, generation:, x1: span.min, x2: span.max, child_xs: xs)
        end
      end
    end

    def bus_segments(bus, lane)
      y = Metrics.top(bus.generation) - Metrics::BUS_ABOVE - lane * Metrics::LANE
      drop = parents(bus.unit).any? ? [ Segment.new(kind: :drop, x1: midpoint(bus.unit), y1: drop_top(bus.unit), x2: midpoint(bus.unit), y2: y) ] : []
      line = bus.x1 < bus.x2 ? [ Segment.new(kind: :bus, x1: bus.x1, y1: y, x2: bus.x2, y2: y) ] : []
      stubs = bus.child_xs.map { |x| Segment.new(kind: :stub, x1: x, y1: y, x2: x, y2: Metrics.top(bus.generation)) }
      drop + line + stubs
    end

    # Greedy interval colouring per row: each bus takes the lowest lane whose
    # previous bus ended before this one starts.
    def lane_of
      buses.group_by(&:generation).values.flat_map do |row|
        ends = []
        row.sort_by(&:x1).map do |bus|
          lane = ends.index { |x2| x2 < bus.x1 } || ends.size
          ends[lane] = bus.x2
          [ bus, lane ]
        end
      end.to_h
    end

    # A child on or above the parents' row (data the tree model cannot place)
    # gets a straight line to the top of its card.
    def links(unit)
      return [] if parents(unit).empty?
      children(unit).reject { |id| at(id).generation > parent_generation(unit) }.map do |id|
        Segment.new(kind: :link, x1: midpoint(unit), y1: drop_top(unit),
          x2: Metrics.centre(at(id).x), y2: Metrics.top(at(id).generation))
      end
    end
  end
end
