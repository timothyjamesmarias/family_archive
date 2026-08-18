require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  def article(published_at:)
    Article.create!(slug: "a-#{SecureRandom.hex(4)}", title: "T", content: "<p>x</p>",
      published_at: published_at)
  end

  test "published gate matches the published scope" do
    live = article(published_at: 1.hour.ago)
    scheduled = article(published_at: 1.hour.from_now)
    draft = article(published_at: nil)

    assert live.published?
    assert_not scheduled.published?
    assert_not draft.published?
    assert_equal [ live.id ], Article.published.ids
  end

  test "rejects slugs that are not lowercase-hyphen" do
    article = Article.new(slug: "Not Valid!", title: "T", content: "")

    assert_not article.valid?
    assert article.errors[:slug].any?
  end

  test "publish! and unpublish! toggle visibility" do
    draft = article(published_at: nil)

    draft.publish!
    assert draft.reload.published?

    draft.unpublish!
    assert_not draft.reload.published?
  end
end
