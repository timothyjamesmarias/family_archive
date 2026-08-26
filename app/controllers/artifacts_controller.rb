class ArtifactsController < ApplicationController
  HUB_PREVIEW_COUNT = 3

  def hub
    @counts = Artifact.group(:artifact_type).count
    @previews = ArtifactType.browsable.to_h do |type|
      [ type.key, Artifact::Browse.display_scope(type).order(created_at: :desc).limit(HUB_PREVIEW_COUNT) ]
    end
  end

  def index
    @type = artifact_type
    @browse = Artifact::Browse.new(type: @type, params: params)
  end

  def show
    @type = artifact_type
    @artifact = Artifact::Browse.display_scope(@type).includes(:commentaries).find_by(slug: params[:slug])
    return redirect_to "/#{@type.route_segment}" if @artifact.nil?

    if @type.reader_tabs
      reader = Artifact::ReaderState.new(artifact: @artifact, type: @type, params: params)
      @leaf = reader.leaf
      @tab = reader.tab
    end
  end

  private

  # Set from the route's defaults, never from user input.
  def artifact_type
    ArtifactType.fetch(params[:type])
  end
end
