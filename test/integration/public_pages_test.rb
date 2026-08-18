require "test_helper"

class PublicPagesTest < ActionDispatch::IntegrationTest
  test "the public pages render" do
    [ root_path, artifacts_hub_path, "/photos", "/letters", articles_path,
      family_tree_path, new_user_session_path ].each do |path|
      get path
      assert_response :success, "expected #{path} to render"
    end
  end

  test "an artifact collection lists only its type" do
    photo = Artifact.create!(slug: "p1", artifact_type: "PHOTO", title: "A Photo",
      storage_path: "x", mime_type: "image/jpeg", file_size: 1)
    Artifact.create!(slug: "l1", artifact_type: "LETTER", title: "A Letter",
      storage_path: "x", mime_type: "image/jpeg", file_size: 1)

    get "/photos"
    assert_match photo.title, response.body
    assert_no_match(/A Letter/, response.body)
  end

  test "an unknown artifact slug redirects to its collection" do
    get "/photos/nope"
    assert_redirected_to "/photos"
  end

  test "unpublished articles 404 and published ones render" do
    draft = Article.create!(slug: "draft", title: "Draft", content: "<p>d</p>")
    live = Article.create!(slug: "live", title: "Live", content: "<p>l</p>",
      published_at: 1.hour.ago)

    get article_path(draft.slug)
    assert_response :not_found

    get article_path(live.slug)
    assert_response :success
  end

  test "the sitemap lists published content and the static pages" do
    Article.create!(slug: "live", title: "Live", content: "", published_at: 1.hour.ago)
    Article.create!(slug: "draft", title: "Draft", content: "")

    get sitemap_path
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
    assert_match "/articles/live", response.body
    assert_no_match(/draft/, response.body)
    assert_match "/family-tree", response.body
  end

  test "robots disallows admin and api" do
    get "/robots.txt"
    assert_match "Disallow: /admin", response.body
    assert_match "sitemap.xml", response.body
  end
end
