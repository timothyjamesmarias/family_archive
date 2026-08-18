module ApplicationHelper
  # Public URL for a stored file, given the `storage_path` held in the database.
  def asset_url_for(storage_path)
    Storage.asset_url(storage_path)
  end

  def icon_tag(name, css: "", stroke: "2")
    render "shared/icon", name: name, css: css, stroke: stroke
  end

  # Article bodies are sanitized when saved; sanitizing again at render keeps
  # the guarantee even for content written outside the admin flow.
  def article_html(article)
    sanitize article.content,
      tags: ArticleHtml::ALLOWED_TAGS, attributes: ArticleHtml::ALLOWED_ATTRIBUTES
  end
end
