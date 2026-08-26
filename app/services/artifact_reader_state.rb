# Resolves a reader page's leaf and tab from the query string. Both fall
# back rather than 404 so stale links still land on the artifact, and tabs
# whose content doesn't exist fall through to Details.
class ArtifactReaderState
  WRITTEN_TABS = %w[transcription translation commentary details].freeze
  PHOTO_TABS = %w[annotations commentary details].freeze

  attr_reader :leaf, :tab

  def initialize(artifact:, type:, params:)
    @artifact = artifact
    tabs = type.key == "PHOTO" ? PHOTO_TABS : WRITTEN_TABS
    @leaf = params[:leaf].to_i.clamp(1, [ artifact.files.size, 1 ].max)
    @tab = params[:tab]
    @tab = tabs.first unless tabs.include?(@tab)
    @tab = "details" unless tab_has_content?(@tab)
  end

  private

  attr_reader :artifact

  def tab_has_content?(tab)
    case tab
    when "transcription" then artifact.transcription.present?
    when "translation" then artifact.transcription&.translations&.any?
    when "commentary" then artifact.commentaries.any?
    when "annotations" then artifact.files.any? { |file| file.annotations.any? }
    else true
    end
  end
end
