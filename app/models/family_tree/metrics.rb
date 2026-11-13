module FamilyTree
  # Pixel geometry of the chart, from the design (Archive Pages, screen 6):
  # 200×76 cards 30px apart, rows 166px apart, a 28px margin round the stage.
  # The layout speaks in slots and rows; everything that draws converts here.
  module Metrics
    CARD_WIDTH = 200
    CARD_HEIGHT = 76
    SLOT = 230
    ROW = 166
    MARGIN = 28
    BRACKET = 34   # a couple's marriage line runs this far below their cards
    BUS_ABOVE = 28 # a sibling bus runs this far above the children's cards
    LANE = 10      # overlapping buses on one row step up a lane each

    module_function

    def left(x) = MARGIN + x * SLOT
    def centre(x) = left(x) + CARD_WIDTH / 2
    def top(generation) = MARGIN + generation * ROW
    def bottom(generation) = top(generation) + CARD_HEIGHT

    # An empty chart (no roots) is 0×0, not negative.
    def stage_width(layout) = layout.width.zero? ? 0 : left(layout.width - 1) + CARD_WIDTH + MARGIN
    def stage_height(layout) = layout.height.zero? ? 0 : bottom(layout.height - 1) + MARGIN
  end
end
