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

  # Replaces Action Text's render, which sanitizes after rendering
  # attachments and so strips the embed components' own markup (Stimulus data
  # attributes, svg). Sanitizing what the author wrote, then rendering embeds,
  # keeps the allowlist on the untrusted part only.
  def render_rich_text(content)
    self.prefix_partial_path_with_controller_namespace = false
    author_html = ActionText::Content.new(sanitize_action_text_content(content), canonicalize: false)
    render_action_text_attachments(author_html).to_html.html_safe
  end
end
