# Resolves a reader page's leaf and tab from the query string. Both fall
# back rather than 404 so stale links still land on the artifact, and tabs
# whose content doesn't exist fall through to Details.
class ArtifactReaderState
  TRANSCRIPTION = "transcription"
  TRANSLATION = "translation"
  COMMENTARY = "commentary"
  ANNOTATIONS = "annotations"
  DETAILS = "details"

  WRITTEN_TABS = [ TRANSCRIPTION, TRANSLATION, COMMENTARY, DETAILS ].freeze
  PHOTO_TABS = [ ANNOTATIONS, COMMENTARY, DETAILS ].freeze

  attr_reader :leaf, :tab

  def initialize(artifact:, type:, params:)
    @artifact = artifact
    tabs = type.key == "PHOTO" ? PHOTO_TABS : WRITTEN_TABS
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
    when ANNOTATIONS then artifact.files.any? { |file| file.annotations.any? }
    else true
    end
  end
end
