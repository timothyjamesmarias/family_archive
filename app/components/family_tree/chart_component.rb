module FamilyTree
  # The chart page's body: the toolbar, then the stage, inside one Turbo Frame
  # so that expanding a card or changing the depth swaps only the chart. All
  # state is in the URL; the component only builds the links that change it.
  class ChartComponent < ApplicationComponent
    DEPTH_LABELS = { 1 => "1", 2 => "2", 3 => "3", Chart::ALL => "All" }.freeze
    DEPTH_PARAMS = { 1 => nil, 2 => "2", 3 => "3", Chart::ALL => "all" }.freeze

    # `mode` is :view or :edit; edit adds a menu to every card and the dialog
    # the menus' forms load into. The controller has already checked that
    # only a signed-in user gets :edit.
    def initialize(chart:, up: [], down: [], depth: 1, mode: :view)
      @chart = chart
      @up = up
      @down = down
      @depth = depth
      @mode = mode
    end

    def edit? = @mode == :edit
    def view_path = chart_path(mode: :view)
    def edit_path = chart_path(mode: :edit)

    def stage_width = Metrics.stage_width(@chart.layout)
    def stage_height = Metrics.stage_height(@chart.layout)

    def segments
      Edges.new(positions: @chart.layout.positions, units: @chart.units).segments
    end

    def depth_path(depth) = chart_path(depth:)
    def expand_up_path(card) = chart_path(up: @up + [ card.person[:id] ], anchor: dom_id(card))
    def expand_down_path(card) = chart_path(down: @down + [ card.person[:id] ], anchor: dom_id(card))

    def dom_id(card) = "person-#{card.person[:id]}"

    # Cards come roots first, so the first one is where "Centre on root" goes.
    def card_attributes(index)
      index.zero? ? { data: { tree_zoom_target: "root" } } : {}
    end

    private

    def chart_path(up: @up, down: @down, depth: @depth, mode: @mode, anchor: nil)
      helpers.family_tree_chart_path(up: up.presence, down: down.presence, depth: DEPTH_PARAMS.fetch(depth),
        edit: (1 if mode == :edit), anchor:)
    end
  end
end
