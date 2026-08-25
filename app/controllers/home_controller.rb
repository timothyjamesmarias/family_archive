class HomeController < ApplicationController
  RECENT_COUNT = 4
  ARTICLE_COUNT = 3

  def index
    attachment = { file_attachment: { blob: :variant_records } }
    @total_artifacts = Artifact.count
    @counts = Artifact.group(:artifact_type).count
    @featured = Artifact.of_type("PHOTO").order(created_at: :desc)
                        .includes(files: attachment).first
    @recent_artifacts = Artifact.order(created_at: :desc).limit(RECENT_COUNT)
                                .includes(files: attachment)
    @recent_articles = Article.published.order(published_at: :desc).limit(ARTICLE_COUNT)
  end
end
