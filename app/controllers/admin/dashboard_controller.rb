module Admin
  class DashboardController < BaseController
    RECENT_ARTIFACTS = 5

    def show
      @counts = {
        individuals: Individual.count,
        families: Family.count,
        places: Place.count,
        artifacts: Artifact.count,
        articles: Article.count,
        users: User.count
      }
      @published_articles = Article.published.count
      @draft_articles = @counts[:articles] - @published_articles
      @recent_artifacts = Artifact.order(uploaded_at: :desc).limit(RECENT_ARTIFACTS)
    end
  end
end
