# Grid tile for the visual collections. Image-first: the scan sits on a
# recessed mat above a serif title and a mono meta line. An annotation
# count, when given, rides the mat's corner.
class ArtifactCardComponent < ApplicationComponent
  def initialize(artifact:, href:, badge_count: nil)
    @artifact = artifact
    @href = href
    @badge_count = badge_count
  end

  private

  attr_reader :artifact, :href, :badge_count

  def title
    artifact.title.presence
  end

  def untitled_label
    artifact.type.untitled_label
  end

  def meta_line
    safe_join([ artifact.original_date_string.presence || "Date unknown", file_count_label ], " · ")
  end

  def file_count_label
    "#{artifact.files.size} #{"file".pluralize(artifact.files.size)}"
  end

  def show_badge?
    badge_count.to_i.positive?
  end
end
