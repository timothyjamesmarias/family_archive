module ApplicationHelper
  def icon_tag(name, css: "", stroke: "2")
    render "shared/icon", name: name, css: css, stroke: stroke
  end

  # The footer's holdings line. Cached because it runs on every public page
  # and drifts slowly; an hour of staleness is invisible in an archive.
  # Swallows storage errors so the error pages can still render while the
  # database is the thing that is broken.
  def archive_holdings_summary
    Rails.cache.fetch("archive_holdings_summary", expires_in: 1.hour) do
      artifact_count = Artifact.count
      individual_count = Individual.count
      "#{number_with_delimiter(artifact_count)} #{"artifact".pluralize(artifact_count)} · " \
        "#{number_with_delimiter(individual_count)} #{"individual".pluralize(individual_count)}"
    end
  rescue StandardError
    nil
  end

  # Article bodies are sanitized when saved; sanitizing again at render keeps
  # the guarantee even for content written outside the admin flow.
  def article_html(article)
    sanitize article.content,
      tags: Article::Html::ALLOWED_TAGS, attributes: Article::Html::ALLOWED_ATTRIBUTES
  end
end
