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

  get "family-tree" => "family_tree_pages#show", as: :family_tree

  # JSON API consumed by the family-tree island. Paths and payloads mirror the
  # AdonisJS app so the island ports over without changes.
  namespace :api, defaults: { format: :json } do
    scope "family-tree" do
      get "initial", to: "family_tree#initial"
      get "expand", to: "family_tree#expand"
      get "individuals/:id/can-delete", to: "family_tree_edits#can_delete", id: /\d+/
      post "individuals", to: "family_tree_edits#create_individual"
      put "individuals/:id", to: "family_tree_edits#update_individual", id: /\d+/
      delete "individuals/:id", to: "family_tree_edits#destroy_individual", id: /\d+/
      post "relationships/child", to: "family_tree_edits#add_child"
      post "relationships/spouse", to: "family_tree_edits#add_spouse"
      post "relationships/parent", to: "family_tree_edits#add_parent"
      post "relationships/link-existing-parent", to: "family_tree_edits#link_existing_parent"
      post "relationships/sibling", to: "family_tree_edits#add_sibling"
    end

    get "individuals/root", to: "individuals#roots"
    get "individuals/:id", to: "individuals#show", id: /\d+/

    put "artifact-files/:file_id/annotations", to: "annotations#replace", file_id: /\d+/
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
