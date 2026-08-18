class ArtifactsController < ApplicationController
  PER_PAGE = 24

  HUB_CARDS = [
    { href: "/photos", title: "Photographs", icon: "photo",
      description: "Family photographs and images through the generations" },
    { href: "/videos", title: "Videos", icon: "video",
      description: "Home movies and video recordings" },
    { href: "/audio", title: "Audio Recordings", icon: "audio",
      description: "Oral histories and audio recordings" },
    { href: "/letters", title: "Letters", icon: "letter",
      description: "Family correspondence and personal letters" },
    { href: "/documents", title: "Documents", icon: "document",
      description: "Historical documents and official records" },
    { href: "/ledgers", title: "Ledgers", icon: "ledger",
      description: "Account books and business ledgers" }
  ].freeze

  def hub
    @cards = HUB_CARDS
  end

  def index
    @type = artifact_type
    @artifacts = Pagination.paginate(
      scope_for(@type), page: params.fetch(:page, 1), per_page: PER_PAGE
    )
  end

  def show
    @type = artifact_type
    @artifact = scope_for(@type).find_by(slug: params[:slug])
    redirect_to "/#{@type.route_segment}" if @artifact.nil?
  end

  private

  # Set from the route's defaults, never from user input.
  def artifact_type
    ArtifactType.fetch(params[:type])
  end

  def scope_for(type)
    attachment = { file_attachment: :blob }
    includes = type.key == "PHOTO" ? [ :annotations, attachment ] : [ attachment ]
    Artifact.of_type(type.key).includes(files: includes)
  end
end
