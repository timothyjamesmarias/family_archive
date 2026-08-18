module Admin
  class UsersController < BaseController
    PER_PAGE = 20
    SEARCH_COLUMNS = %w[name email].freeze

    def index
      scope = User.order(:name)
      scope = search(scope) if params[:q].present?
      @users = Pagination.paginate(
        scope, page: params.fetch(:page, 1), per_page: PER_PAGE
      )
    end

    def show
      @user = User.find(params[:id])
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_user_path(@user), notice: "User created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])
      if @user.update(user_params_for_update)
        redirect_to admin_user_path(@user), notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Refuses to delete the signed-in account: doing so would destroy the
    # session mid-request and can leave the install with no way back in.
    def destroy
      user = User.find(params[:id])
      if user == current_user
        redirect_to admin_users_path, alert: "You cannot delete your own account."
        return
      end

      user.destroy
      redirect_to admin_users_path, notice: "User deleted."
    end

    private

    def search(scope)
      pattern = "%#{User.sanitize_sql_like(params[:q])}%"
      clauses = SEARCH_COLUMNS.map { |column| "#{column} ILIKE :pattern" }.join(" OR ")
      scope.where(clauses, pattern: pattern)
    end

    def user_params
      params.expect(user: [ :name, :email, :password, :admin ])
    end

    # A blank password on edit means "keep the current one".
    def user_params_for_update
      attributes = user_params
      attributes[:password].present? ? attributes : attributes.except(:password)
    end
  end
end
