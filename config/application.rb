require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FamilyArchive
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks generators])

    # Component previews (/rails/view_components in development) render in a
    # layout that loads the public design system, not the app chrome.
    config.view_component.previews.default_layout = "component_preview"

    # Error pages render through the app (screen 14) so they share the real
    # layout and recipes. There are no static fallback pages — they would
    # shadow the /404 and /500 routes — so if the error pages themselves
    # raise, ShowExceptions serves Rails' plain-text failsafe.
    config.exceptions_app = routes

    # The jobs dashboard inherits the admin gate (authenticate_user! +
    # require_admin) instead of Mission Control's default HTTP basic auth.
    config.mission_control.jobs.base_controller_class = "Admin::BaseController"
    config.mission_control.jobs.http_basic_auth_enabled = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
