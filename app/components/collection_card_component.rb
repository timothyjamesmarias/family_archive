# One collection on the hub: a preview strip of the collection's own
# contents over its name, count, and description. Visual and written types
# preview real scans; audio gets a waveform and video a play slate, both
# decorative, on the dusty wash.
class CollectionCardComponent < ApplicationComponent
  # Deterministic bar heights — a decoration, not a chart.
  WAVEFORM_HEIGHTS = [ 22, 46, 68, 40, 78, 54, 30, 62, 44, 82, 36, 58, 26, 70,
                       48, 34, 64, 42, 74, 30, 56, 80, 38, 66, 28, 52, 44, 72, 34, 60 ].freeze

  def initialize(type:, count:, preview_artifacts: [])
    @type = type
    @count = count
    @preview_artifacts = preview_artifacts
  end

  private

  attr_reader :type, :count, :preview_artifacts

  def href
    "/#{type.route_segment}"
  end

  def preview_style
    return :waveform if type.key == "AUDIO"
    return :slate if type.key == "VIDEO"

    :scans
  end
end
