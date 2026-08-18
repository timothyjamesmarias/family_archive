class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :slug, null: false
      t.string :title, limit: 500, null: false
      t.string :excerpt, limit: 1000
      t.text :content, null: false
      t.datetime :published_at
      t.timestamps
    end
    add_index :articles, :slug, unique: true
    add_index :articles, :published_at
  end
end
