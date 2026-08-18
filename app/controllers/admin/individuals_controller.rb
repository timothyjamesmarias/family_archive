module Admin
  class IndividualsController < BaseController
    PER_PAGE = 20
    SEARCH_COLUMNS = %w[given_name surname gedcom_id].freeze

    def index
      scope = Individual.order(:surname, :given_name)
      scope = search(scope) if params[:q].present?
      @individuals = Pagination.paginate(
        scope, page: params.fetch(:page, 1), per_page: PER_PAGE
      )
    end

    def show
      @individual = Individual.find(params[:id])
    end

    def new
      @individual = Individual.new
    end

    def create
      @individual = Individual.new(individual_params)
      if @individual.save
        demote_previous_root(@individual)
        redirect_to admin_individual_path(@individual), notice: "Individual created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @individual = Individual.find(params[:id])
    end

    def update
      @individual = Individual.find(params[:id])
      if @individual.update(individual_params)
        demote_previous_root(@individual)
        redirect_to admin_individual_path(@individual), notice: "Individual updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      Individual.find(params[:id]).destroy
      redirect_to admin_individuals_path, notice: "Individual deleted."
    end

    private

    # Only one individual may be the tree root. Demotion runs after a
    # successful write, so a rejected form never leaves the tree rootless.
    def demote_previous_root(individual)
      return unless individual.is_tree_root?

      Individual.tree_roots.where.not(id: individual.id).update_all(is_tree_root: false)
    end

    def search(scope)
      pattern = "%#{Individual.sanitize_sql_like(params[:q])}%"
      clauses = SEARCH_COLUMNS.map { |column| "#{column} ILIKE :pattern" }.join(" OR ")
      scope.where(clauses, pattern: pattern)
    end

    def individual_params
      attributes = params.expect(individual: [ :gedcom_id, :given_name, :surname, :sex, :is_tree_root ])
      attributes.merge(
        gedcom_id: attributes[:gedcom_id].presence,
        sex: attributes[:sex].presence
      )
    end
  end
end
