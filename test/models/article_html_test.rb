require "test_helper"

class ArticleHtmlTest < ActiveSupport::TestCase
  test "keeps the editor's vocabulary" do
    html = '<h2>Title</h2><p>Text with <strong>bold</strong> and <a href="https://x.test">a link</a></p>'

    assert_equal html, Article::Html.sanitize(html)
  end

  test "strips script tags but keeps their surroundings" do
    dirty = "<p>before</p><script>alert(1)</script><p>after</p>"

    clean = Article::Html.sanitize(dirty)
    assert_no_match(/<script/, clean)
    assert_match(/before/, clean)
    assert_match(/after/, clean)
  end

  test "removes javascript: urls" do
    clean = Article::Html.sanitize('<a href="javascript:alert(1)">x</a>')

    assert_no_match(/javascript:/, clean)
  end

  test "removes event handler attributes" do
    clean = Article::Html.sanitize('<p onclick="alert(1)">x</p>')

    assert_no_match(/onclick/, clean)
  end
end
