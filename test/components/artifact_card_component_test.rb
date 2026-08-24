require "test_helper"

class ArtifactCardComponentTest < ViewComponent::TestCase
  test "titled card with date and file count" do
    artifact = Artifact.new(artifact_type: "PHOTO", slug: "farmhouse",
                            title: "Family gathered outside the farmhouse",
                            original_date_string: "c. 1947")

    render_inline(ArtifactCardComponent.new(artifact: artifact, href: "/photos/farmhouse"))

    assert_selector "a[href='/photos/farmhouse']"
    assert_selector ".font-serif", text: "Family gathered outside the farmhouse"
    assert_selector ".meta", text: "c. 1947 · 0 files"
  end

  test "untitled artifacts fall back to an italic label and unknown date" do
    artifact = Artifact.new(artifact_type: "PHOTO", slug: "mystery")

    render_inline(ArtifactCardComponent.new(artifact: artifact, href: "/photos/mystery"))

    assert_selector ".italic", text: "Untitled photo"
    assert_selector ".meta", text: /Date unknown/
  end

  test "annotation badge renders only for a positive count" do
    artifact = Artifact.new(artifact_type: "PHOTO", slug: "crew", title: "Harvest crew")

    render_inline(ArtifactCardComponent.new(artifact: artifact, href: "#", badge_count: 9))
    assert_selector ".mat span.font-mono", text: "9"

    render_inline(ArtifactCardComponent.new(artifact: artifact, href: "#", badge_count: 0))
    assert_no_selector ".mat span.font-mono"
  end

  test "without files the mat shows the type icon" do
    artifact = Artifact.new(artifact_type: "LEDGER", slug: "accounts", title: "Store accounts")

    render_inline(ArtifactCardComponent.new(artifact: artifact, href: "#"))

    assert_selector ".mat svg"
    assert_no_selector ".mat img"
  end
end
