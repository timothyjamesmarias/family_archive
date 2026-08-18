module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin

    layout "admin"

    private

    def require_admin
      return if current_user.can_administer?

      redirect_to root_path, alert: "Not authorized."
    end
  end
end
