require "test_helper"

class ArtifactRowComponentTest < ViewComponent::TestCase
  def letter(title: "Letter from Anna Marias to her brother", date: "18 April 1931")
    Artifact.new(artifact_type: "LETTER", slug: "anna-1931", title: title, original_date_string: date)
  end

  test "renders chip, date, title, and snippet" do
    render_inline(ArtifactRowComponent.new(
      artifact: letter, href: "/letters/anna-1931",
      snippet: "My dear brother — we leave on the fourteenth from Bremen"
    ))

    assert_selector "a[href='/letters/anna-1931']"
    assert_selector ".chip.chip-terracotta.chip-sm", text: "Letter"
    assert_selector ".meta", text: "18 April 1931"
    assert_selector ".font-serif", text: "Letter from Anna Marias to her brother"
    assert_selector "p.font-serif", text: /My dear brother/
  end

  test "status chips come from the caller" do
    render_inline(ArtifactRowComponent.new(artifact: letter, href: "#")) do |row|
      row.with_status { "Transcribed" }
      row.with_status(tone: :attention) { "Needs transcription" }
    end

    assert_selector ".chip-status.chip-status-sm", text: "Transcribed"
    assert_selector ".chip-status-attention", text: "Needs transcription"
  end

  test "fallback note replaces the snippet for untranscribed items" do
    render_inline(ArtifactRowComponent.new(
      artifact: letter(title: nil, date: nil), href: "#",
      fallback_note: "No transcription yet."
    ))

    assert_selector ".italic", text: "Untitled letter"
    assert_selector ".meta", text: "Date unknown"
    assert_selector "p", text: "No transcription yet."
    assert_no_selector "p.font-serif"
  end
end
