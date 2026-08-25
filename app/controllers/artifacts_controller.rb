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

  READER_TABS = %w[transcription translation commentary details].freeze

  def show
    @type = artifact_type
    @artifact = scope_for(@type).includes(:commentaries).find_by(slug: params[:slug])
    return redirect_to "/#{@type.route_segment}" if @artifact.nil?

    prepare_reader if @type.written_record?
  end

  private

  # Set from the route's defaults, never from user input.
  def artifact_type
    ArtifactType.fetch(params[:type])
  end

  # The reader's leaf and tab come from the query string; both fall back
  # rather than 404 so stale links still land on the artifact.
  def prepare_reader
    @leaf = params[:leaf].to_i.clamp(1, [ @artifact.files.size, 1 ].max)
    @tab = params[:tab]
    @tab = "transcription" unless READER_TABS.include?(@tab)
    @tab = "details" unless reader_tab_has_content?(@tab)
  end

  def reader_tab_has_content?(tab)
    case tab
    when "transcription" then @artifact.transcription.present?
    when "translation" then @artifact.transcription&.translations&.any?
    when "commentary" then @artifact.commentaries.any?
    else true
    end
  end

  def scope_for(type)
    attachment = { file_attachment: { blob: :variant_records } }
    includes = type.key == "PHOTO" ? [ :annotations, attachment ] : [ attachment ]
    Artifact.of_type(type.key).includes({ files: includes }, transcription: :translations)
  end
end
