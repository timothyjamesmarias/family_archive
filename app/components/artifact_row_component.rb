# List row for the textual collections: thumbnail, chip + mono date, serif
# title, an optional transcription snippet, and a meta column of status
# chips the page supplies. Rows stack inside one bordered sheet.
class ArtifactRowComponent < ApplicationComponent
  renders_many :statuses, ->(tone: :neutral) { Ui::StatusChipComponent.new(tone: tone, size: :sm) }

  def initialize(artifact:, href:, snippet: nil, fallback_note: nil)
    @artifact = artifact
    @href = href
    @snippet = snippet
    @fallback_note = fallback_note
  end

  private

  attr_reader :artifact, :href, :snippet, :fallback_note

  def title
    artifact.title.presence
  end

  def untitled_label
    artifact.type.untitled_label
  end

  def date_label
    artifact.original_date_string.presence || "Date unknown"
  end

  def file_count_label
    "#{artifact.files.size} #{"file".pluralize(artifact.files.size)}"
  end
end
