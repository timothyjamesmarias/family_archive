class ArtifactType
  attr_reader :key, :display_name, :plural_display_name, :route_segment, :empty_icon,
    :chip_label, :browse_layout, :description, :category, :reader_partial, :reader_tabs,
    :index_filters

  # Chip tone follows the category — written records are terracotta, images
  # sage, time-based media dusty (design foundations, section 04). Tone is
  # assigned, never chosen, so behavior keys off the category and the tone
  # stays presentation.
  CATEGORY_CHIP_TONES = {
    written: "terracotta",
    image: "sage",
    audio_visual: "dusty",
    other: "taupe"
  }.freeze

  def initialize(key:, display_name:, plural_display_name:, route_segment:, empty_icon:,
    chip_label:, browse_layout:, description:, category:, reader_partial:, reader_tabs:,
    index_filters:)
    @key = key
    @display_name = display_name
    @plural_display_name = plural_display_name
    @route_segment = route_segment
    @empty_icon = empty_icon
    @chip_label = chip_label
    @browse_layout = browse_layout
    @description = description
    @category = category
    @reader_partial = reader_partial
    @reader_tabs = reader_tabs
    @index_filters = index_filters
    freeze
  end

  # Visual types browse as a grid; textual ones as a list whose rows can
  # carry a transcription snippet. Each type declares its detail rendering
  # (reader_partial), which tab set the reader offers (reader_tabs), and
  # which finding-aid pills its index shows (index_filters).
  ALL = [
    new(key: "PHOTO", display_name: "Photo", plural_display_name: "Photographs",
        route_segment: "photos", empty_icon: "photo", chip_label: "Photograph",
        browse_layout: :grid, category: :image, reader_partial: "photo_reader",
        reader_tabs: :photo, index_filters: %w[annotated],
        description: "Family photographs and images through the generations"),
    new(key: "LETTER", display_name: "Letter", plural_display_name: "Letters",
        route_segment: "letters", empty_icon: "letter", chip_label: "Letter",
        browse_layout: :list, category: :written, reader_partial: "reader",
        reader_tabs: :written, index_filters: %w[transcribed translated],
        description: "Family correspondence and personal letters"),
    new(key: "DOCUMENT", display_name: "Document", plural_display_name: "Documents",
        route_segment: "documents", empty_icon: "document", chip_label: "Document",
        browse_layout: :list, category: :written, reader_partial: "reader",
        reader_tabs: :written, index_filters: %w[transcribed translated],
        description: "Historical documents and official records"),
    new(key: "LEDGER", display_name: "Ledger", plural_display_name: "Ledgers",
        route_segment: "ledgers", empty_icon: "ledger", chip_label: "Ledger",
        browse_layout: :list, category: :written, reader_partial: "reader",
        reader_tabs: :written, index_filters: %w[transcribed translated],
        description: "Account books and business ledgers"),
    new(key: "AUDIO", display_name: "Audio Recording", plural_display_name: "Audio Recordings",
        route_segment: "audio", empty_icon: "audio", chip_label: "Audio",
        browse_layout: :list, category: :audio_visual, reader_partial: "audio_reader",
        reader_tabs: nil, index_filters: %w[transcribed translated],
        description: "Oral histories and audio recordings"),
    new(key: "VIDEO", display_name: "Video Recording", plural_display_name: "Videos",
        route_segment: "videos", empty_icon: "video", chip_label: "Video",
        browse_layout: :grid, category: :audio_visual, reader_partial: "video_reader",
        reader_tabs: nil, index_filters: [],
        description: "Home movies and video recordings"),
    new(key: "OTHER", display_name: "Other", plural_display_name: "Other",
        route_segment: "other", empty_icon: "document", chip_label: "Other",
        browse_layout: :list, category: :other, reader_partial: nil,
        reader_tabs: nil, index_filters: [],
        description: nil)
  ].freeze

  def grid?
    browse_layout == :grid
  end

  def written_record?
    category == :written
  end

  def image?
    category == :image
  end

  def chip_tone
    CATEGORY_CHIP_TONES.fetch(category)
  end

  def untitled_label
    "Untitled #{chip_label.downcase}"
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
