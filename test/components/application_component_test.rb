require "test_helper"

class ApplicationComponentTest < ViewComponent::TestCase
  class Probe < ApplicationComponent
    def call
      tag.span("ok", class: "probe")
    end
  end

  test "components render through the Rails view stack" do
    render_inline Probe.new

    assert_selector "span.probe", text: "ok"
  end
end
