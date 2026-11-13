require "test_helper"

class ArticleEmbedsTest < ActionDispatch::IntegrationTest
  setup do
    @letter = Artifact.create!(slug: "letter-1923", artifact_type: "LETTER", title: "Letter from 1923")
    @letter.create_transcription!(transcription_text: "Dear Anna")
  end

  def attachment_html(embed)
    %(<action-text-attachment sgid="#{embed.attachable_sgid}" content-type="#{embed.attachable_content_type}"></action-text-attachment>)
  end

  def embed(options = {})
    Embed.build_for(kind: "artifact", embeddable_id: @letter.id, options:).tap(&:save!)
  end

  test "the public page sanitizes what the author wrote but keeps the embed's markup" do
    letter = embed("show_transcription" => "1")
    Article.create!(slug: "a", title: "A", published_at: 1.hour.ago, content: <<~HTML)
      <p onclick="alert(1)">ok</p><script>alert(1)</script><a href="javascript:alert(1)">x</a>
      <svg><circle r="1"></circle></svg>
      #{attachment_html(letter)}
    HTML

    get article_path("a")

    assert_response :success
    body = css_select(".prose-article").to_html
    assert_no_match(/<script|onclick|javascript:/, body)
    assert_select ".prose-article svg", count: 1 # the embed's thumbnail icon; the author's was stripped
    assert_select ".prose-article figure svg"
    assert_select ".prose-article figure a[href='/letters/letter-1923']", "Letter from 1923"
    assert_select ".prose-article figure", /Dear Anna/
  end

  test "embed options are off unless chosen" do
    Article.create!(slug: "a", title: "A", published_at: 1.hour.ago, content: attachment_html(embed))

    get article_path("a")

    assert_no_match(/Dear Anna/, response.body)
  end

  test "saving an article claims its embeds and drops the ones edited out" do
    kept, removed = embed, embed
    article = Article.create!(slug: "a", title: "A", content: attachment_html(kept) + attachment_html(removed))
    assert_equal [ kept, removed ].sort, article.embeds.sort

    article.update!(content: attachment_html(kept))

    assert_equal [ kept ], article.reload.embeds
    assert_not Embed.exists?(removed.id)

    article.destroy!
    assert_not Embed.exists?(kept.id)
  end

  test "the insert dialog lists the kind's menu and returns attachment markup" do
    sign_in create_admin

    get new_admin_embed_path(kind: "artifact")
    assert_select "select[name='embed[embeddable_id]'] option[value='#{@letter.id}']", "Letter from 1923 · Letter"
    assert_select "input[type=checkbox][name='embed[options][show_annotations]']"

    assert_difference -> { Embed.count } do
      post admin_embeds_path, params: { embed: {
        kind: "artifact", embeddable_id: @letter.id,
        options: { show_annotations: "0", show_transcription: "1", bogus: "1" }
      } }
    end

    embed = Embed.last
    assert_equal({ "show_annotations" => false, "show_transcription" => true }, embed.options)
    assert_select "template action-text-attachment[sgid='#{embed.attachable_sgid}'][content]"
  end
end
