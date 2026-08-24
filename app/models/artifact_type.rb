class ArtifactType
  attr_reader :key, :display_name, :plural_display_name, :route_segment, :empty_icon, :chip_tone

  def initialize(key:, display_name:, plural_display_name:, route_segment:, empty_icon:, chip_tone:)
    @key = key
    @display_name = display_name
    @plural_display_name = plural_display_name
    @route_segment = route_segment
    @empty_icon = empty_icon
    @chip_tone = chip_tone
    freeze
  end

  # Chip tone is assigned, never chosen: written records are terracotta,
  # images sage, time-based media dusty (design foundations, section 04).
  ALL = [
    new(key: "PHOTO", display_name: "Photo", plural_display_name: "Photos",
        route_segment: "photos", empty_icon: "photo", chip_tone: "sage"),
    new(key: "LETTER", display_name: "Letter", plural_display_name: "Letters",
        route_segment: "letters", empty_icon: "letter", chip_tone: "terracotta"),
    new(key: "DOCUMENT", display_name: "Document", plural_display_name: "Documents",
        route_segment: "documents", empty_icon: "document", chip_tone: "terracotta"),
    new(key: "LEDGER", display_name: "Ledger", plural_display_name: "Ledgers",
        route_segment: "ledgers", empty_icon: "ledger", chip_tone: "terracotta"),
    new(key: "AUDIO", display_name: "Audio Recording", plural_display_name: "Audio",
        route_segment: "audio", empty_icon: "audio", chip_tone: "dusty"),
    new(key: "VIDEO", display_name: "Video Recording", plural_display_name: "Videos",
        route_segment: "videos", empty_icon: "video", chip_tone: "dusty"),
    new(key: "OTHER", display_name: "Other", plural_display_name: "Other",
        route_segment: "other", empty_icon: "document", chip_tone: "taupe")
  ].freeze

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
