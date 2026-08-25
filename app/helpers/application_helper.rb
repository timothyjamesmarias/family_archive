module ApplicationHelper
  def icon_tag(name, css: "", stroke: "2")
    render "shared/icon", name: name, css: css, stroke: stroke
  end

  # The footer's holdings line. Cached because it runs on every public page
  # and drifts slowly; an hour of staleness is invisible in an archive.
  def archive_holdings_summary
    Rails.cache.fetch("archive_holdings_summary", expires_in: 1.hour) do
      "#{number_with_delimiter(Artifact.count)} artifacts · #{number_with_delimiter(Individual.count)} individuals"
    end
  end

  # Article bodies are sanitized when saved; sanitizing again at render keeps
  # the guarantee even for content written outside the admin flow.
  def article_html(article)
    sanitize article.content,
      tags: ArticleHtml::ALLOWED_TAGS, attributes: ArticleHtml::ALLOWED_ATTRIBUTES
  end
end
