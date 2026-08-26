# Serves the designed error pages through exceptions_app. Inherits
# ActionController::Base, not ApplicationController: these actions must run
# for exactly the requests the rest of the app refuses — a POST re-raising
# InvalidAuthenticityToken inside the error dispatch would downgrade the
# styled page to Rails' bare-text failsafe, and the allow_browser gate
# would hand old browsers the 406 page instead of the error they hit.
class ErrorsController < ActionController::Base
  skip_forgery_protection

  layout "public"

  def not_found
    render status: :not_found
  end

  def unprocessable
    @status_code = 422
    @status_label = "request rejected"
    render :internal_error, status: :unprocessable_content
  end

  def internal_error
    @status_code = 500
    @status_label = "server error"
    render status: :internal_server_error
  end
end
