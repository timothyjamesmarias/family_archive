module Api
  # JSON endpoints under /api. Domain errors are mapped in one place so the
  # same error class cannot mean 400 on one endpoint and 404 on another, and an
  # unrecognised failure stays a logged 500 rather than being reported as the
  # user's mistake.
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception

    rescue_from DomainError, with: :render_domain_error
    rescue_from ActiveRecord::RecordNotFound do
      render json: { errors: { id: "Not found" } }, status: :not_found
    end
    # A CSRF failure must be a real status code, not a redirect to an HTML page.
    rescue_from ActionController::InvalidAuthenticityToken do
      render json: { errors: { form: "Invalid or missing CSRF token" } }, status: :forbidden
    end

    private

    def render_domain_error(error)
      field = error.field || "form"
      render json: { errors: { field => error.message } }, status: status_for(error)
    end

    def status_for(error)
      case error
      when ::NotFoundError then :not_found
      when ::ConflictError then :conflict
      else :bad_request
      end
    end

    # Devise's HTML fallback is a redirect to the sign-in page; the island
    # needs a status code it can react to.
    def require_authenticated_user!
      return if user_signed_in?

      render json: { errors: { session: "Authentication required" } }, status: :unauthorized
    end
  end
end
