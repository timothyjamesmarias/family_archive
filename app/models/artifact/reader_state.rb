# Resolves a reader page's leaf and tab from the query string. Both fall
# back rather than 404 so stale links still land on the artifact, and tabs
# whose content doesn't exist fall through to Details. Annotations are
# leaf-scoped: the panel shows the current leaf's, so availability does too.
class Artifact::ReaderState
  TRANSCRIPTION = "transcription"
  TRANSLATION = "translation"
  COMMENTARY = "commentary"
  ANNOTATIONS = "annotations"
  DETAILS = "details"

  TAB_SETS = {
    written: [ TRANSCRIPTION, TRANSLATION, COMMENTARY, DETAILS ].freeze,
    photo: [ ANNOTATIONS, COMMENTARY, DETAILS ].freeze
  }.freeze

  attr_reader :leaf, :tab

  def initialize(artifact:, type:, params:)
    @artifact = artifact
    tabs = TAB_SETS.fetch(type.reader_tabs)
    @leaf = params[:leaf].to_i.clamp(1, [ artifact.files.size, 1 ].max)
    @tab = params[:tab]
    @tab = tabs.first unless tabs.include?(@tab)
    @tab = DETAILS unless tab_has_content?(@tab)
  end

  private

  attr_reader :artifact

  def tab_has_content?(tab)
    case tab
    when TRANSCRIPTION then artifact.transcription.present?
    when TRANSLATION then artifact.transcription&.translations&.any?
    when COMMENTARY then artifact.commentaries.any?
    when ANNOTATIONS then artifact.files[leaf - 1]&.annotations&.any?
    else true
    end
  end
end
