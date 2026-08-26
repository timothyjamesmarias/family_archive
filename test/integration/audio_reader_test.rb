require "test_helper"

class AudioReaderTest < ActionDispatch::IntegrationTest
  def interview(with_file: true)
    if with_file
      artifact = ArtifactUploader.new.upload(
        files: [ fixture_file_upload("artifact.png", "image/png") ],
        artifact_type: "AUDIO", title: "Interview with Katharina Marias"
      )
    else
      artifact = Artifact.create!(slug: "tape", artifact_type: "AUDIO",
                                  title: "Interview with Katharina Marias")
    end
    Transcription.create!(artifact: artifact,
      transcription_text: "The boat, I remember the boat better than the arrival.\n\nAnd the field — she never spoke of the field.")
    artifact
  end

  test "the audio reader renders the player band over the transcript" do
    artifact = interview

    get "/audio/#{artifact.slug}"

    assert_response :success
    assert_select "[data-controller='media-player'] audio[src]"
    assert_select "button[aria-label='Play']"
    assert_select "button[aria-label='Seek']"
    assert_select "a", text: "Download"
    assert_match "Transcript", response.body
    assert_match "I remember the boat", response.body
    assert_select "dl dt", text: "Identifier"
    assert_select "nav[aria-label='Breadcrumb'] a", text: "Audio Recordings"
  end

  test "without a file the transcript still renders and the player does not" do
    artifact = interview(with_file: false)

    get "/audio/#{artifact.slug}"

    assert_response :success
    assert_select "[data-controller='media-player']", count: 0
    assert_match "I remember the boat", response.body
  end
end
