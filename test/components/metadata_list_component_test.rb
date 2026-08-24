require "test_helper"

class MetadataListComponentTest < ViewComponent::TestCase
  test "renders term/value rows with arbitrary value content" do
    render_inline(MetadataListComponent.new) do |list|
      list.with_row(term: "Identifier") { "letter-anna-1931-04" }
      list.with_row(term: "People") { %(<a class="link-person" href="#">Anna Marias</a>).html_safe }
    end

    assert_selector "dl dt", count: 2
    assert_selector "dt", text: "Identifier"
    assert_selector "dd", text: "letter-anna-1931-04"
    assert_selector "dd a.link-person", text: "Anna Marias"
  end
end
