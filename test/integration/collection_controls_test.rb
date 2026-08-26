require "test_helper"

class CollectionControlsTest < ActionDispatch::IntegrationTest
  def letter(slug, title:, text: nil, uploaded_at: Time.current)
    artifact = Artifact.create!(slug: slug, artifact_type: "LETTER", title: title, uploaded_at: uploaded_at)
    Transcription.create!(artifact: artifact, transcription_text: text) if text
    artifact
  end

  test "the collection search matches titles and transcriptions" do
    letter("bremen", title: "Passage plans", text: "We sail from Bremen in April.")
    letter("linens", title: "About the linens")

    get "/letters", params: { q: "bremen" }
    assert_match "Passage plans", response.body
    assert_no_match(/About the linens/, response.body)

    get "/letters", params: { q: "linens" }
    assert_match "About the linens", response.body
    assert_no_match(/Passage plans/, response.body)
  end

  test "sort order can be flipped" do
    letter("first", title: "Oldest letter", uploaded_at: 2.years.ago)
    letter("last", title: "Newest letter", uploaded_at: 1.day.ago)

    get "/letters"
    assert_operator response.body.index("Oldest letter"), :<, response.body.index("Newest letter")

    get "/letters", params: { sort: "newest" }
    assert_operator response.body.index("Newest letter"), :<, response.body.index("Oldest letter")
  end

  test "the transcribed pill narrows the list" do
    letter("with", title: "Transcribed letter", text: "Some text")
    letter("without", title: "Silent letter")

    get "/letters", params: { transcribed: "1" }

    assert_match "Transcribed letter", response.body
    assert_no_match(/Silent letter/, response.body)
    assert_select "a.pill.pill-active", text: /Transcribed/
  end

  test "a list collection can switch to the grid view" do
    letter("one", title: "A letter")

    get "/letters", params: { view: "grid" }

    assert_select ".segment-active", text: "Grid"
    assert_select "a[href*='view=list']"
  end

  test "photos offer the annotated pill only" do
    Artifact.create!(slug: "p1", artifact_type: "PHOTO", title: "A photo")

    get "/photos"

    assert_select "a.pill", text: "Annotated"
    assert_select "a.pill", text: "Transcribed", count: 0
  end
end
