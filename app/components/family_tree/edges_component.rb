module FamilyTree
  # The chart's lines, drawn under the cards: one SVG path per kind of
  # segment, so the stylesheet can treat a bus differently from a bracket.
  class EdgesComponent < ApplicationComponent
    def initialize(segments:, width:, height:)
      @segments = segments
      @width = width
      @height = height
    end

    def paths
      @segments.group_by(&:kind).transform_values do |segments|
        segments.map { |s| "M#{s.x1} #{s.y1}L#{s.x2} #{s.y2}" }.join
      end
    end
  end
end
