Rails.application.routes.draw do
  devise_for :users, path: "", path_names: { sign_in: "login", sign_out: "logout" },
                     skip: [ :registrations ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  get "sitemap.xml" => "sitemaps#show", as: :sitemap
  get "robots.txt" => "sitemaps#robots"

  get "artifacts" => "artifacts#hub", as: :artifacts_hub
  get "search" => "searches#show", as: :search

  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable", via: :all
  match "/500", to: "errors#internal_error", via: :all

  # One typed collection per browsable artifact type: /photos, /photos/:slug, ...
  ArtifactType.browsable.each do |type|
    get type.route_segment, to: "artifacts#index", defaults: { type: type.key },
        as: :"#{type.route_segment}_artifacts"
    get "#{type.route_segment}/:slug", to: "artifacts#show", defaults: { type: type.key },
        as: :"#{type.route_segment}_artifact"
  end

  resources :articles, only: [ :index, :show ], param: :slug

  # The server-rendered chart; its state (depth, up[], down[], edit) is the URL.
  get "family-tree" => "family_tree_charts#show", as: :family_tree
  # Edit mode on the chart: forms load into the page's dialog frame, a save
  # redirects back to the chart URL it came from.
  scope "family-tree", as: :family_tree do
    resources :people, only: %i[edit update destroy], controller: "family_tree_people" do
      get :delete, on: :member
      resources :relatives, only: %i[new create], controller: "family_tree_relatives"
    end
  end

  namespace :admin do
    root "dashboard#show"

    resources :users
    resources :places
    resources :individuals
    resources :families
    resources :articles do
      member do
        post :publish
        post :unpublish
      end
    end
    resource :gedcom_import, only: [ :show, :create ]

    resources :artifacts, constraints: { id: /\d+/ } do
      member do
        post :add_files
        delete "files/:file_id", action: :destroy_file, as: :file, file_id: /\d+/
        get :annotations
      end
    end

    resources :artifact_files, only: [] do
      resources :annotations, only: %i[new create edit update destroy]
    end

    # One collection page per artifact type (/admin/artifacts/photos, ...),
    # mirroring the public typed routes. Same index action with the type pinned.
    get "artifacts/:segment", to: "artifacts#index", as: :typed_artifacts,
        constraints: { segment: Regexp.union(ArtifactType::ALL.map(&:route_segment)) }
  end

  # Solid Queue dashboard. Admin-gated in the MissionControl base controller
  # (config/initializers/mission_control.rb).
  mount MissionControl::Jobs::Engine, at: "/admin/jobs"

  root "home#index"
end
