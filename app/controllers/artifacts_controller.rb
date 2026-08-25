class ArtifactsController < ApplicationController
  PER_PAGE = 24
  HUB_PREVIEW_COUNT = 3

  def hub
    @counts = Artifact.group(:artifact_type).count
    @previews = ArtifactType.browsable.to_h do |type|
      [ type.key, scope_for(type).order(created_at: :desc).limit(HUB_PREVIEW_COUNT) ]
    end
  end

  def index
    @type = artifact_type
    @artifacts = Pagination.paginate(
      scope_for(@type), page: params.fetch(:page, 1), per_page: PER_PAGE
    )
    @transcribed_count = scope_for(@type).joins(:transcription).count unless @type.grid?
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
    attachment = { file_attachment: { blob: :variant_records } }
    includes = type.key == "PHOTO" ? [ :annotations, attachment ] : [ attachment ]
    Artifact.of_type(type.key).includes({ files: includes }, transcription: :translations)
  end
end
