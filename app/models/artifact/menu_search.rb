# The embed picker's artifact menu: every artifact as a [label, id] option,
# which the browser fuzzy-filters as the admin types. The label carries the
# type so "photo francis" narrows, and untitled artifacts carry their slug so
# they can be told apart.
# ponytail: loads every artifact into one menu; swap in a server-side query
# here when the archive outgrows that or site search lands.
class Artifact::MenuSearch
  def options
    Artifact.order(:title, :slug).map { |artifact| [ label(artifact), artifact.id ] }
  end

  private

  def label(artifact)
    return "#{artifact.title} · #{artifact.type.display_name}" if artifact.title.present?

    "#{artifact.type.untitled_label} · #{artifact.slug}"
  end
end
