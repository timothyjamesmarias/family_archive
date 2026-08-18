class CreateArtifactTables < ActiveRecord::Migration[8.1]
  def change
    create_table :artifacts do |t|
      t.string :slug, null: false
      t.string :artifact_type, limit: 50, null: false
      t.string :title, limit: 500
      t.datetime :uploaded_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.string :original_date_string
      t.timestamps
    end
    add_index :artifacts, :slug, unique: true
    add_index :artifacts, :artifact_type

    # The stored object lives in Active Storage (has_one_attached :file); this
    # row carries the artifact's ordering and the annotation anchor.
    create_table :artifact_files do |t|
      t.references :artifact, null: false, foreign_key: { on_delete: :cascade }
      t.integer :file_sequence, null: false
      t.timestamps
    end
    add_index :artifact_files, [ :artifact_id, :file_sequence ], unique: true

    create_table :annotations do |t|
      t.references :artifact_file, null: false, foreign_key: { on_delete: :cascade }
      t.text :annotation_text, null: false
      t.decimal :x_coord, precision: 10, scale: 6
      t.decimal :y_coord, precision: 10, scale: 6
      t.timestamps
    end

    create_table :transcriptions do |t|
      t.references :artifact, null: false, foreign_key: { on_delete: :cascade }
      t.text :transcription_text, null: false
      t.timestamps
    end

    create_table :translations do |t|
      t.references :transcription, null: false, foreign_key: { on_delete: :cascade }
      t.text :translated_text, null: false
      t.string :target_language, limit: 10, null: false
      t.timestamps
    end

    create_table :commentaries do |t|
      t.references :artifact, null: false, foreign_key: { on_delete: :cascade }
      t.text :commentary_text, null: false
      t.string :commentary_type, limit: 50
      t.timestamps
    end
  end
end
