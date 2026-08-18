module Admin
  class PlacesController < BaseController
    PER_PAGE = 20
    SEARCH_COLUMNS = %w[name city state_province country].freeze

    def index
      scope = Place.order(:name)
      scope = search(scope) if params[:q].present?
      @places = Pagination.paginate(
        scope, page: params.fetch(:page, 1), per_page: PER_PAGE
      )
    end

    def show
      @place = Place.find(params[:id])
    end

    def new
      @place = Place.new
    end

    def create
      @place = Place.new(place_params)
      if @place.save
        redirect_to admin_place_path(@place), notice: "Place created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @place = Place.find(params[:id])
    end

    def update
      @place = Place.find(params[:id])
      if @place.update(place_params)
        redirect_to admin_place_path(@place), notice: "Place updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      Place.find(params[:id]).destroy
      redirect_to admin_places_path, notice: "Place deleted."
    end

    private

    def search(scope)
      pattern = "%#{Place.sanitize_sql_like(params[:q])}%"
      clauses = SEARCH_COLUMNS.map { |column| "#{column} ILIKE :pattern" }.join(" OR ")
      scope.where(clauses, pattern: pattern)
    end

    def place_params
      params.expect(place: [ :name, :city, :state_province, :country, :latitude, :longitude ])
    end
  end
end
