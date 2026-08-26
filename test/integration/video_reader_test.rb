require "test_helper"

class VideoReaderTest < ActionDispatch::IntegrationTest
  def film(with_file: true)
    return Artifact.create!(slug: "reel", artifact_type: "VIDEO", title: "The store, filmed on 8mm") unless with_file

    Artifact::Uploader.new.upload(
      files: [ fixture_file_upload("artifact.png", "image/png") ],
      artifact_type: "VIDEO", title: "The store, filmed on 8mm"
    )
  end

  test "the video reader leads with the frame on the ink board" do
    artifact = film

    get "/videos/#{artifact.slug}"

    assert_response :success
    assert_select ".bg-ink-800 [data-controller='media-player'] video[src]"
    assert_select "button[aria-label='Play']"
    assert_select "button", text: "Full screen"
    assert_select ".chip-dusty", text: "Video"
    assert_select "h1", "The store, filmed on 8mm"
    assert_select "dl dt", text: "Identifier"
    assert_select "nav[aria-label='Breadcrumb'] a", text: "Videos"
  end

  test "without a file the header and details still render" do
    artifact = film(with_file: false)

    get "/videos/#{artifact.slug}"

    assert_response :success
    assert_select "[data-controller='media-player']", count: 0
    assert_select "h1", "The store, filmed on 8mm"
  end
end
