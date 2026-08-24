# Metadata list, empty state, messages, tabs, pagination, breadcrumbs —
# the smaller patterns, gathered on one page.
class RecordPatternsPreview < ViewComponent::Preview
  # @label Metadata list
  def metadata
    render_with_template
  end

  # @label Empty state
  def empty_state
    render_with_template
  end

  # @label Messages
  def messages
    render_with_template
  end

  # @label Tabs & pagination
  def navigation
    render_with_template
  end
end
