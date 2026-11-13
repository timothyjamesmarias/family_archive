# A record placed into rich text through the admin's "Insert embed" dialog.
# The article HTML holds only this row's sgid; the row says what to show and
# how, because Lexxy drops any attribute it doesn't know from the tag.
class Embed < ApplicationRecord
  include ActionText::Attachable

  # Every kind of thing an admin can embed. Adding one: an entry here, the
  # component it names, and a menu search: an object whose #options returns
  # the picker's [label, id] pairs.
  KINDS = {
    "artifact" => {
      label: "Artifact",
      model: "Artifact",
      component: "Embeds::ArtifactComponent",
      options: %w[show_annotations show_transcription],
      search: "Artifact::MenuSearch"
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

  def self.menu_options(kind)
    KINDS.fetch(kind)[:search].constantize.new.options
  end

  # Called when `record` stops showing this embed. An embed copied into
  # another editor shares its sgid, so it moves to the rich text that still
  # shows it; with none left it goes.
  # ponytail: LIKE scan of every rich text body per release; index or track
  # references if the archive's articles ever make that slow.
  def release_from(record)
    pattern = "%#{self.class.sanitize_sql_like(attachable_sgid)}%"
    holder = ActionText::RichText.where.not(record:).where("body LIKE ?", pattern).pick(:record_type, :record_id)
    holder ? update_columns(owner_type: holder.first, owner_id: holder.last) : delete
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
