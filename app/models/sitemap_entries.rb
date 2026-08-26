# Every publicly reachable URL. Excludes /login, /up, /api/* and /admin/*.
class SitemapEntries
  ARTICLE_PRIORITY = "0.6"
  ARTIFACT_PRIORITY = "0.5"

  STATIC_PAGES = [
    { path: "/", changefreq: "weekly", priority: "1.0" },
    { path: "/artifacts", changefreq: "weekly", priority: "0.8" },
    { path: "/articles", changefreq: "weekly", priority: "0.8" },
    { path: "/family-tree", changefreq: "weekly", priority: "0.8" },
    *ArtifactType.browsable.map do |type|
      { path: "/#{type.route_segment}", changefreq: "weekly", priority: "0.7" }
    end
  ].freeze

  def entries(base_url)
    [
      *STATIC_PAGES.map do |page|
        { loc: "#{base_url}#{page[:path]}", lastmod: nil,
          changefreq: page[:changefreq], priority: page[:priority] }
      end,
      *published_articles.map do |article|
        { loc: "#{base_url}/articles/#{article.slug}",
          lastmod: article.updated_at.utc.iso8601,
          changefreq: "monthly", priority: ARTICLE_PRIORITY }
      end,
      *routable_artifacts.map do |artifact|
        { loc: "#{base_url}/#{artifact.type.route_segment}/#{artifact.slug}",
          lastmod: artifact.updated_at.utc.iso8601,
          changefreq: "monthly", priority: ARTIFACT_PRIORITY }
      end
    ]
  end

  private

  # Matches the published gate the article pages apply, so the sitemap never
  # lists a slug that 404s.
  def published_articles
    Article.published.order(published_at: :desc).select(:slug, :updated_at)
  end

  def routable_artifacts
    Artifact.of_type(ArtifactType.browsable.map(&:key))
      .order(updated_at: :desc)
      .select(:slug, :artifact_type, :updated_at)
  end
end
