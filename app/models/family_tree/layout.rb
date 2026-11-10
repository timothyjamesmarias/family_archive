module FamilyTree
  # Positions the people of a loaded tree on a grid. `x` is a card centre in
  # slots (one card plus its gutter; leftmost card centre at 0), `generation`
  # an integer row with the top row at 0. Pure data in, pure data out: the view
  # multiplies slots into pixels and draws edges from the units it already has.
  #
  # Order is meaning in the input: the first parent of a unit is drawn on the
  # left, children are laid out in the order given. The layout never reorders
  # siblings — birth order is a convention genealogists expect.
  class Layout
    Unit = Data.define(:id, :parent_ids, :child_ids)
    Position = Data.define(:x, :generation)

    def initialize(individual_ids:, units:)
      @individual_ids = individual_ids
      @units = units
    end

    def positions
      @positions ||= begin
        forest = Forest.new(@individual_ids, @units)
        forest.trees.each { |tree| TidyTree.new(tree.root).call }
        Packing.new(forest).call
        normalised_positions(forest)
      end
    end

    def width = (positions.values.map(&:x).max || -1) + 1
    def height = (positions.values.map(&:generation).max || -1) + 1

    # One line per generation, ids at twice the slot resolution, so a
    # couple's child shows up between them. For tests, the console and the
    # curious; collisions after rounding are accepted.
    def sketch
      cell = (positions.keys.map { |id| id.to_s.size }.max || 1) + 1

      positions.group_by { |_, position| position.generation }.sort.map { |_, row|
        row.sort_by { |_, position| position.x }.each_with_object(+"") do |(id, position), line|
          column = (position.x * 2).round * cell
          line << " " * (column - line.size) if column > line.size
          line << " " if column < line.size
          line << id.to_s
        end
      }.join("\n")
    end

    private

    # Shift so the leftmost real card is at 0 and the top real row is 0;
    # phantoms may sit above or beside that and are never reported.
    def normalised_positions(forest)
      placed = forest.blocks.reject(&:phantom?).flat_map do |block|
        block.members.map { |id| [ id, block.x_of(id), block.depth ] }
      end
      return {} if placed.empty?

      left = placed.map { |_, x, _| x }.min
      top = placed.map { |_, _, depth| depth }.min
      placed.to_h { |id, x, depth| [ id, Position.new(x: x - left, generation: depth - top) ] }
    end
  end
end
