require "test_helper"

class ArticlesIndexTest < ActionDispatch::IntegrationTest
  def publish(slug, title:, at:, excerpt: nil)
    Article.create!(slug: slug, title: title, content: "<p>Body</p>", excerpt: excerpt, published_at: at)
  end

  test "the newest article is featured with the Latest mark" do
    publish("older", title: "Reading a ledger sideways", at: 2.weeks.ago)
    publish("newest", title: "What the smaller field was worth", at: 1.day.ago,
            excerpt: "The April 1931 letter is the only document that puts a price on the land.")

    get articles_path

    assert_select "a.border-l-heather-500 h2", text: "What the smaller field was worth"
    assert_select "a.border-l-heather-500 span", text: "Latest"
    assert_select "a.border-l-heather-500 p.italic", text: /puts a price on the land/
    assert_select "a:not(.border-l-heather-500) h2", text: "Reading a ledger sideways"
  end

  test "drafts stay out and the count reflects published articles" do
    publish("live", title: "Six weeks at sea", at: 1.day.ago)
    Article.create!(slug: "draft", title: "Unfinished", content: "<p>x</p>")

    get articles_path

    assert_match "1 article.", response.body
    assert_no_match(/Unfinished/, response.body)
  end

  test "an empty index states it plainly" do
    get articles_path

    assert_match "Nothing published yet", response.body
  end
end
