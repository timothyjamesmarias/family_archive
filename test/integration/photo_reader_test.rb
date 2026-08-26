require "test_helper"

class PhotoReaderTest < ActionDispatch::IntegrationTest
  def photo_with_annotations
    artifact = Artifact::Uploader.new.upload(
      files: [ fixture_file_upload("artifact.png", "image/png") ],
      artifact_type: "PHOTO", title: "Family gathered outside the farmhouse"
    )
    file = artifact.files.first
    file.annotations.create!(annotation_text: "Anna, seated centre, holding the youngest child.",
                             x_coord: 0.38, y_coord: 0.28)
    file.annotations.create!(annotation_text: "Josef, standing by the porch rail.",
                             x_coord: 0.16, y_coord: 0.34)
    artifact
  end

  test "the photo reader renders markers and the annotation list in sync" do
    artifact = photo_with_annotations

    get "/photos/#{artifact.slug}"

    assert_response :success
    assert_select "a.tab.tab-active", text: /Annotations/
    assert_select "a.tab .font-mono", text: "2"
    assert_select "[data-controller='photo-annotations']"
    assert_select "button.annotation-dot.annotation-marker", count: 2
    assert_select "button.annotation-row", count: 2
    assert_select "button.annotation-row", text: /Anna, seated centre/
    assert_select "[role='switch'][aria-checked='true']"
    assert_select "a", text: "Download"
    assert_select "nav[aria-label='Breadcrumb'] a", text: "Photographs"
  end

  test "markers carry their normalized coordinates" do
    artifact = photo_with_annotations

    get "/photos/#{artifact.slug}"

    assert_match "left: 38.0%; top: 28.0%;", response.body
  end

  test "the details tab renders the metadata list" do
    artifact = photo_with_annotations

    get "/photos/#{artifact.slug}?tab=details"

    assert_select "dl dt", text: "Identifier"
    assert_select "dd", text: /1 file/
  end

  test "the annotations tab is scoped to the current leaf" do
    artifact = Artifact::Uploader.new.upload(
      files: [ fixture_file_upload("artifact.png", "image/png"),
               fixture_file_upload("artifact.png", "image/png") ],
      artifact_type: "PHOTO", title: "Two leaves"
    )
    artifact.files.last.annotations.create!(annotation_text: "Only on leaf 2", x_coord: 0.5, y_coord: 0.5)

    get "/photos/#{artifact.slug}"
    assert_select "a.tab.tab-active", text: /Details/

    get "/photos/#{artifact.slug}?leaf=2"
    assert_select "a.tab.tab-active", text: /Annotations/
    assert_select "button.annotation-row", text: /Only on leaf 2/
  end
end
