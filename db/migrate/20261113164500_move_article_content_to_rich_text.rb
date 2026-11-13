# Article bodies move into Action Text so Lexxy can edit them and embeds can
# reference records. Embeds hold the per-insertion options Lexxy would drop
# from the attachment tag.
class MoveArticleContentToRichText < ActiveRecord::Migration[8.1]
  def up
    create_table :embeds do |t|
      t.string :kind, null: false
      t.references :embeddable, polymorphic: true, null: false
      # Null until the article holding it is saved; an embed inserted into a
      # new article has nothing to belong to yet.
      t.references :owner, polymorphic: true
      t.jsonb :options, null: false, default: {}
      t.timestamps
    end

    execute <<~SQL
      INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
      SELECT 'content', content, 'Article', id, created_at, updated_at FROM articles
    SQL
    remove_column :articles, :content
  end

  def down
    add_column :articles, :content, :text, null: false, default: ""
    execute <<~SQL
      UPDATE articles SET content = rich.body
      FROM action_text_rich_texts rich
      WHERE rich.record_type = 'Article' AND rich.record_id = articles.id AND rich.name = 'content'
    SQL
    execute "DELETE FROM action_text_rich_texts WHERE record_type = 'Article'"
    drop_table :embeds
  end
end
