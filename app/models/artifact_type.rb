class ArtifactType
  attr_reader :key, :display_name, :plural_display_name, :route_segment, :empty_icon,
    :chip_tone, :chip_label, :browse_layout, :description

  def initialize(key:, display_name:, plural_display_name:, route_segment:, empty_icon:,
    chip_tone:, chip_label:, browse_layout:, description:)
    @key = key
    @display_name = display_name
    @plural_display_name = plural_display_name
    @route_segment = route_segment
    @empty_icon = empty_icon
    @chip_tone = chip_tone
    @chip_label = chip_label
    @browse_layout = browse_layout
    @description = description
    freeze
  end

  # Chip tone is assigned, never chosen: written records are terracotta,
  # images sage, time-based media dusty (design foundations, section 04).
  # Visual types browse as a grid; textual ones as a list whose rows can
  # carry a transcription snippet.
  ALL = [
    new(key: "PHOTO", display_name: "Photo", plural_display_name: "Photographs",
        route_segment: "photos", empty_icon: "photo", chip_tone: "sage", chip_label: "Photograph", browse_layout: :grid,
        description: "Family photographs and images through the generations"),
    new(key: "LETTER", display_name: "Letter", plural_display_name: "Letters",
        route_segment: "letters", empty_icon: "letter", chip_tone: "terracotta", chip_label: "Letter", browse_layout: :list,
        description: "Family correspondence and personal letters"),
    new(key: "DOCUMENT", display_name: "Document", plural_display_name: "Documents",
        route_segment: "documents", empty_icon: "document", chip_tone: "terracotta", chip_label: "Document", browse_layout: :list,
        description: "Historical documents and official records"),
    new(key: "LEDGER", display_name: "Ledger", plural_display_name: "Ledgers",
        route_segment: "ledgers", empty_icon: "ledger", chip_tone: "terracotta", chip_label: "Ledger", browse_layout: :list,
        description: "Account books and business ledgers"),
    new(key: "AUDIO", display_name: "Audio Recording", plural_display_name: "Audio Recordings",
        route_segment: "audio", empty_icon: "audio", chip_tone: "dusty", chip_label: "Audio", browse_layout: :list,
        description: "Oral histories and audio recordings"),
    new(key: "VIDEO", display_name: "Video Recording", plural_display_name: "Videos",
        route_segment: "videos", empty_icon: "video", chip_tone: "dusty", chip_label: "Video", browse_layout: :grid,
        description: "Home movies and video recordings"),
    new(key: "OTHER", display_name: "Other", plural_display_name: "Other",
        route_segment: "other", empty_icon: "document", chip_tone: "taupe", chip_label: "Other", browse_layout: :list,
        description: nil)
  ].freeze

  def grid?
    browse_layout == :grid
  end

  def untitled_label
    "Untitled #{chip_label.downcase}"
  end

  def written_record?
    chip_tone == "terracotta"
  end

  BY_KEY = ALL.index_by(&:key).freeze

  KEYS = BY_KEY.keys.freeze

  # OTHER has no public route, so it never appears in navigation or the sitemap.
  def self.browsable
    ALL.reject { |type| type.key == "OTHER" }
  end

  BY_ROUTE_SEGMENT = ALL.index_by(&:route_segment).freeze

  def self.fetch(key)
    BY_KEY.fetch(key)
  end

  # Returns nil for an unrecognised value so callers reject it rather than
  # silently storing the artifact as OTHER.
  def self.from_string(value)
    BY_KEY[value.to_s.upcase]
  end
end
