class ArtifactsController < ApplicationController
  PER_PAGE = 24
  HUB_PREVIEW_COUNT = 3

  def hub
    @counts = Artifact.group(:artifact_type).count
    @previews = ArtifactType.browsable.to_h do |type|
      [ type.key, scope_for(type).order(created_at: :desc).limit(HUB_PREVIEW_COUNT) ]
    end
  end

  SORT_ORDERS = {
    "newest" => { uploaded_at: :desc },
    "oldest" => { uploaded_at: :asc },
    "title" => Arel.sql("title ASC NULLS LAST")
  }.freeze

  # Which pills a collection offers, keyed by what its records can carry.
  FILTER_SCOPES = {
    "annotated" => ->(scope) { scope.joins(files: :annotations) },
    "transcribed" => ->(scope) { scope.joins(:transcription) },
    "translated" => ->(scope) { scope.joins(transcription: :translations) }
  }.freeze

  def index
    @type = artifact_type
    @view = %w[grid list].include?(params[:view]) ? params[:view] : @type.browse_layout.to_s
    @query = params[:q].to_s.strip
    @sort = SORT_ORDERS.key?(params[:sort]) ? params[:sort] : default_sort
    @filters = available_filters.select { |filter| params[filter] == "1" }
    @artifacts = Pagination.paginate(
      filtered_scope.order(SORT_ORDERS.fetch(@sort)),
      page: params.fetch(:page, 1), per_page: PER_PAGE
    )
    @transcribed_count = Artifact.of_type(@type.key).joins(:transcription).count unless @type.grid?
  end

  WRITTEN_TABS = %w[transcription translation commentary details].freeze
  PHOTO_TABS = %w[annotations commentary details].freeze

  def show
    @type = artifact_type
    @artifact = scope_for(@type).includes(:commentaries).find_by(slug: params[:slug])
    return redirect_to "/#{@type.route_segment}" if @artifact.nil?

    prepare_reader if @type.written_record? || @type.key == "PHOTO"
  end

  private

  # Set from the route's defaults, never from user input.
  def artifact_type
    ArtifactType.fetch(params[:type])
  end

  # The reader's leaf and tab come from the query string; both fall back
  # rather than 404 so stale links still land on the artifact.
  def prepare_reader
    tabs = @type.key == "PHOTO" ? PHOTO_TABS : WRITTEN_TABS
    @leaf = params[:leaf].to_i.clamp(1, [ @artifact.files.size, 1 ].max)
    @tab = params[:tab]
    @tab = tabs.first unless tabs.include?(@tab)
    @tab = "details" unless reader_tab_has_content?(@tab)
  end

  def reader_tab_has_content?(tab)
    case tab
    when "transcription" then @artifact.transcription.present?
    when "translation" then @artifact.transcription&.translations&.any?
    when "commentary" then @artifact.commentaries.any?
    when "annotations" then @artifact.files.any? { |file| file.annotations.any? }
    else true
    end
  end

  def scope_for(type)
    attachment = { file_attachment: { blob: :variant_records } }
    includes = type.key == "PHOTO" ? [ :annotations, attachment ] : [ attachment ]
    Artifact.of_type(type.key).includes({ files: includes }, transcription: :translations)
  end

  # The photos mockup sorts newest first; the letters mockup oldest first.
  def default_sort
    @type.grid? ? "newest" : "oldest"
  end

  def available_filters
    return [ "annotated" ] if @type.key == "PHOTO"
    return %w[transcribed translated] if @type.written_record? || @type.key == "AUDIO"

    []
  end
  helper_method :available_filters

  # Filters and the collection search narrow via id subqueries so the
  # joins can't inflate counts or fight the eager loads. The search is a
  # plain ILIKE over titles and transcriptions — a finding aid, not the
  # future search feature.
  def filtered_scope
    scope = scope_for(@type)
    return scope if @query.blank? && @filters.empty?

    narrowed = Artifact.of_type(@type.key)
    if @query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      narrowed = narrowed.left_joins(:transcription)
        .where("artifacts.title ILIKE :q OR transcriptions.transcription_text ILIKE :q", q: pattern)
    end
    @filters.each { |filter| narrowed = FILTER_SCOPES.fetch(filter).call(narrowed) }
    scope.where(id: narrowed.select(:id))
  end
end
