require "application_system_test_case"

class ArticleEmbedsSystemTest < ApplicationSystemTestCase
  test "an admin inserts an artifact embed into an article and it survives a re-save" do
    letter = Artifact.create!(slug: "letter-1923", artifact_type: "LETTER", title: "Letter from 1923")
    letter.create_transcription!(transcription_text: "Dear Anna")
    Artifact.create!(slug: "ledger-1923", artifact_type: "LEDGER", title: "Ledger 1923")
    Artifact.create!(slug: "anna", artifact_type: "PHOTO", title: "Anna at the lake")
    article = Article.create!(slug: "story", title: "Story", content: "<p>Intro</p>")
    sign_in_as email: "boss@example.com", admin: true

    visit edit_admin_article_path(article)
    assert_selector "lexxy-editor", text: "Intro"
    click_on "Insert embed"
    within "dialog" do
      find("input[name=filter]").set("ltr 23")
      assert_no_selector "option", text: "Anna at the lake"
      assert_equal "Letter from 1923 · Letter", find("select[name='embed[embeddable_id]'] option", match: :first).text
      assert_equal letter.id.to_s, find("select[name='embed[embeddable_id]']").value
      check "Show transcription"
      click_on "Insert"
    end

    assert_no_selector "dialog[open]"
    assert_selector "lexxy-editor action-text-attachment", text: "Letter from 1923"
    click_on "Update Article"
    assert_text "Article updated."

    embed = article.reload.embeds.sole
    assert embed.option?("show_transcription")

    # Re-saving through the editor must keep the reference Lexxy loaded.
    visit edit_admin_article_path(article)
    assert_selector "lexxy-editor action-text-attachment", text: "Letter from 1923"
    click_on "Update Article"
    assert_text "Article updated."
    assert_equal [ embed ], article.reload.embeds
  end
end
