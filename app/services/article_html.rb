# Article bodies are written as HTML in the admin editor and rendered
# unescaped on a public page, so they are sanitized on the way in — client-side
# editor restrictions are a convenience and are bypassed by posting directly.
#
# The allowlist covers what a rich-text toolbar produces and nothing else.
module ArticleHtml
  ALLOWED_TAGS = %w[
    p br hr span div h1 h2 h3 h4 h5 h6
    strong b em i u s strike sub sup
    blockquote pre code ul ol li a img
    table thead tbody tfoot tr th td caption col colgroup
    figure figcaption
    fa-artifact
  ].freeze

  ALLOWED_ATTRIBUTES = %w[
    style class id title
    href name target rel
    src alt width height loading
    colspan rowspan scope span
    type caption show-annotations show-transcription
  ].freeze

  module_function

  # Rails::HTML5::SafeListSanitizer already strips javascript:/data: URLs and
  # unsafe inline styles; the tag/attribute lists narrow it to the editor's
  # vocabulary.
  def sanitize(html)
    Rails::HTML5::SafeListSanitizer.new.sanitize(
      html.to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES
    ).to_s
  end
end
