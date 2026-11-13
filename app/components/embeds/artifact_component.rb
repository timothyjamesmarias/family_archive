# An artifact placed in an article. Unstyled until the embed is designed.
class Embeds::ArtifactComponent < ApplicationComponent
  def initialize(embed:)
    @embed = embed
    @artifact = embed.embeddable
  end

  private

  attr_reader :embed, :artifact

  def title
    artifact.title.presence || artifact.type.untitled_label
  end

  def href
    "/#{artifact.type.route_segment}/#{artifact.slug}"
  end

  def annotations
    return [] unless embed.option?("show_annotations")

    artifact.files.flat_map(&:annotations)
  end

  def transcription
    artifact.transcription&.transcription_text if embed.option?("show_transcription")
  end
end
