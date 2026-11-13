# A record placed into rich text through the admin's "Insert embed" dialog.
# The article HTML holds only this row's sgid; the row says what to show and
# how, because Lexxy drops any attribute it doesn't know from the tag.
class Embed < ApplicationRecord
  include ActionText::Attachable

  # Every kind of thing an admin can embed. Adding one: an entry here and the
  # component it names. `search` returns [label, id] pairs for the picker.
  KINDS = {
    "artifact" => {
      label: "Artifact",
      model: "Artifact",
      component: "Embeds::ArtifactComponent",
      options: %w[show_annotations show_transcription],
      search: ->(query) {
        Artifact.where("title ILIKE ?", "%#{Artifact.sanitize_sql_like(query)}%")
          .order(:title).limit(20)
          .map { |artifact| [ artifact.title.presence || artifact.type.untitled_label, artifact.id ] }
      }
    }
  }.freeze

  belongs_to :embeddable, polymorphic: true
  belongs_to :owner, polymorphic: true, optional: true

  validates :kind, inclusion: { in: KINDS.keys }

  def self.build_for(kind:, embeddable_id:, options: {})
    definition = KINDS.fetch(kind)
    new(
      kind: kind,
      embeddable: definition[:model].constantize.find(embeddable_id),
      options: options.slice(*definition[:options]).transform_values { ActiveModel::Type::Boolean.new.cast(it) }
    )
  end

  def definition
    KINDS.fetch(kind)
  end

  def option?(name)
    options[name] == true
  end

  def component
    definition[:component].constantize.new(embed: self)
  end

  def to_attachable_partial_path
    "embeds/embed"
  end

  def attachable_content_type
    "application/vnd.archive.embed"
  end

  def attachable_plain_text_representation(caption = nil)
    "[#{caption || definition[:label]}]"
  end
end
