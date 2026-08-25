# Serves the designed error pages through exceptions_app. Must stay
# resilient: these actions can run while the rest of the app is failing.
class ErrorsController < ApplicationController
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
