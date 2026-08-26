# Assembles one collection index page from its query-string state: view,
# sort, collection search, filter pills, and the paginated scope. The
# controller hands over the type and params; the view reads everything else
# from here.
class ArtifactBrowse
  PER_PAGE = 24

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

  attr_reader :type, :view, :query, :sort, :filters

  # Everything an artifact page displays, eager-loaded in one shape.
  def self.display_scope(type)
    attachment = { file_attachment: { blob: :variant_records } }
    includes = type.key == "PHOTO" ? [ :annotations, attachment ] : [ attachment ]
    Artifact.of_type(type.key).includes({ files: includes }, transcription: :translations)
  end

  def initialize(type:, params:)
    @type = type
    @params = params
    @view = %w[grid list].include?(params[:view]) ? params[:view] : type.browse_layout.to_s
    @query = params[:q].to_s.strip
    @sort = SORT_ORDERS.key?(params[:sort]) ? params[:sort] : default_sort
    @filters = available_filters.select { |filter| params[filter] == "1" }
  end

  def artifacts
    @artifacts ||= Pagination.paginate(
      filtered_scope.order(SORT_ORDERS.fetch(sort)),
      page: @params.fetch(:page, 1), per_page: PER_PAGE
    )
  end

  def grid?
    view == "grid"
  end

  def available_filters
    return [ "annotated" ] if type.key == "PHOTO"
    return %w[transcribed translated] if type.written_record? || type.key == "AUDIO"

    []
  end

  def total_in_collection
    @total_in_collection ||= Artifact.of_type(type.key).count
  end

  def transcribed_count
    @transcribed_count ||= Artifact.of_type(type.key).joins(:transcription).count
  end

  # The state every control link carries; pagination adds its page on top.
  def control_params
    state = { q: query.presence, sort: sort, view: view }.compact
    filters.each { |filter| state[filter] = "1" }
    state
  end

  private

  # The photos mockup sorts newest first; the letters mockup oldest first.
  def default_sort
    type.grid? ? "newest" : "oldest"
  end

  # Filters and the collection search narrow via id subqueries so the
  # joins can't inflate counts or fight the eager loads. The search is a
  # plain ILIKE over titles and transcriptions — a finding aid, not the
  # future search feature.
  def filtered_scope
    scope = self.class.display_scope(type)
    return scope if query.blank? && filters.empty?

    narrowed = Artifact.of_type(type.key)
    if query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      narrowed = narrowed.left_joins(:transcription)
        .where("artifacts.title ILIKE :q OR transcriptions.transcription_text ILIKE :q", q: pattern)
    end
    filters.each { |filter| narrowed = FILTER_SCOPES.fetch(filter).call(narrowed) }
    scope.where(id: narrowed.select(:id))
  end
end
