# The embed picker's artifact menu: every browsable artifact (OTHER has no
# public page to link to) as a [label, id] option, which the browser
# fuzzy-filters as the admin types. The label carries the type so
# "photo francis" narrows, and untitled artifacts carry their slug so they
# can be told apart.
# ponytail: loads every artifact into one menu; swap in a server-side query
# here when the archive outgrows that or site search lands.
class Artifact::MenuSearch
  def options
    Artifact.browsable.order(:title, :slug)
      .pluck(:id, :title, :slug, :artifact_type)
      .map { |id, title, slug, type_key| [ label(title, slug, ArtifactType.fetch(type_key)), id ] }
  end

  private

  def label(title, slug, type)
    return "#{title} · #{type.display_name}" if title.present?

    "#{type.untitled_label} · #{slug}"
  end
end
