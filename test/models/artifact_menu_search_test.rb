require "test_helper"

class ArtifactMenuSearchTest < ActiveSupport::TestCase
  test "lists every artifact by title and type, untitled ones by slug" do
    letter = Artifact.create!(slug: "letter-1923", artifact_type: "LETTER", title: "Letter from 1923")
    photo = Artifact.create!(slug: "7af4e7d1", artifact_type: "PHOTO")

    assert_equal [
      [ "Letter from 1923 · Letter", letter.id ],
      [ "Untitled photograph · 7af4e7d1", photo.id ]
    ], Artifact::MenuSearch.new.options
  end
end
