module Admin
  class FamiliesController < BaseController
    PER_PAGE = 20

    def index
      scope = Family.order(:id).includes(:marriage_place, members: :individual)
      scope = search(scope) if params[:q].present?
      @families = Pagination.paginate(
        scope, page: params.fetch(:page, 1), per_page: PER_PAGE
      )
    end

    def show
      @family = Family.includes(:marriage_place, members: :individual).find(params[:id])
    end

    def new
      @family = Family.new
    end

    def create
      @family = Family.new(family_params)
      if @family.save
        redirect_to admin_family_path(@family), notice: "Family created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @family = Family.find(params[:id])
    end

    def update
      @family = Family.find(params[:id])
      if @family.update(family_params)
        redirect_to admin_family_path(@family), notice: "Family updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      Family.find(params[:id]).destroy
      redirect_to admin_families_path, notice: "Family deleted."
    end

    private

    # Search spans relations (member names, marriage place), so a plain column
    # scan cannot express it.
    def search(scope)
      pattern = "%#{Family.sanitize_sql_like(params[:q])}%"
      matching_ids = Family
        .left_joins(:marriage_place, members: :individual)
        .where(<<~SQL.squish, pattern: pattern)
          families.gedcom_id ILIKE :pattern
          OR individuals.given_name ILIKE :pattern
          OR individuals.surname ILIKE :pattern
          OR places.name ILIKE :pattern
        SQL
        .distinct
        .ids
      scope.where(id: matching_ids)
    end

    def family_params
      attributes = params.expect(family: [
        :gedcom_id, :marriage_date_string, :marriage_place_id, :divorce_date_string
      ])
      attributes.merge(
        gedcom_id: attributes[:gedcom_id].presence,
        marriage_place_id: attributes[:marriage_place_id].presence,
        marriage_date_parsed: parse_date(attributes[:marriage_date_string]),
        divorce_date_parsed: parse_date(attributes[:divorce_date_string])
      )
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
  end
end
