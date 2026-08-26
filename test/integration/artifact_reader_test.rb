require "test_helper"

class ArtifactReaderTest < ActionDispatch::IntegrationTest
  def letter_with_transcription
    letter = Artifact.create!(slug: "anna-1931", artifact_type: "LETTER",
                              title: "Letter from Anna Marias to her brother",
                              original_date_string: "18 April 1931")
    transcription = Transcription.create!(artifact: letter,
      transcription_text: "My dear brother — we leave on the fourteenth.\n\nWrite to the address I sent.")
    Translation.create!(transcription: transcription, target_language: "de",
      translated_text: "Mein lieber Bruder.")
    letter
  end

  test "a written record renders the reader with its transcription" do
    letter = letter_with_transcription

    get "/letters/#{letter.slug}"

    assert_response :success
    assert_select "h1", letter.title
    assert_match "Verbatim", response.body
    assert_match "we leave on the fourteenth", response.body
    assert_select "a.tab", text: /Translation/
    assert_select "a.tab", text: /Details/
    assert_select "nav[aria-label='Breadcrumb'] a", text: "Letters"
  end

  test "the translation tab renders the derived text on the dusty wash" do
    letter = letter_with_transcription

    get "/letters/#{letter.slug}?tab=translation"

    assert_response :success
    assert_match "Machine translation &mdash; DE", response.body
    assert_match "Mein lieber Bruder", response.body
  end

  test "tabs without content fall back to details" do
    bare = Artifact.create!(slug: "mystery", artifact_type: "LETTER")

    get "/letters/#{bare.slug}?tab=translation"

    assert_response :success
    assert_match bare.slug, response.body
    assert_select "a.tab", text: /Details/
    assert_select "a.tab", text: /Transcription/, count: 0
  end

  test "a photo without annotations opens on details" do
    photo = Artifact.create!(slug: "farm", artifact_type: "PHOTO", title: "Farmhouse")

    get "/photos/#{photo.slug}"

    assert_response :success
    assert_select "a.tab.tab-active", text: /Details/
    assert_select "a.tab", text: /Annotations/, count: 0
  end
end
