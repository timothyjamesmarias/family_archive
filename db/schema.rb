# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_13_164500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "annotations", force: :cascade do |t|
    t.bigint "artifact_file_id", null: false
    t.text "annotation_text", null: false
    t.decimal "x_coord", precision: 10, scale: 6
    t.decimal "y_coord", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_file_id"], name: "index_annotations_on_artifact_file_id"
  end

  create_table "articles", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", limit: 500, null: false
    t.string "excerpt", limit: 1000
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
  end

  create_table "artifact_files", force: :cascade do |t|
    t.bigint "artifact_id", null: false
    t.integer "file_sequence", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_id", "file_sequence"], name: "index_artifact_files_on_artifact_id_and_file_sequence", unique: true
    t.index ["artifact_id"], name: "index_artifact_files_on_artifact_id"
  end

  create_table "artifacts", force: :cascade do |t|
    t.string "slug", null: false
    t.string "artifact_type", limit: 50, null: false
    t.string "title", limit: 500
    t.datetime "uploaded_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "original_date_string"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_type"], name: "index_artifacts_on_artifact_type"
    t.index ["slug"], name: "index_artifacts_on_slug", unique: true
  end

  create_table "commentaries", force: :cascade do |t|
    t.bigint "artifact_id", null: false
    t.text "commentary_text", null: false
    t.string "commentary_type", limit: 50
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_id"], name: "index_commentaries_on_artifact_id"
  end

  create_table "embeds", force: :cascade do |t|
    t.string "kind", null: false
    t.string "embeddable_type", null: false
    t.bigint "embeddable_id", null: false
    t.string "owner_type"
    t.bigint "owner_id"
    t.jsonb "options", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["embeddable_type", "embeddable_id"], name: "index_embeds_on_embeddable"
    t.index ["owner_type", "owner_id"], name: "index_embeds_on_owner"
  end

  create_table "families", force: :cascade do |t|
    t.string "gedcom_id", limit: 50
    t.string "marriage_date_string"
    t.datetime "marriage_date_parsed"
    t.bigint "marriage_place_id"
    t.string "divorce_date_string"
    t.datetime "divorce_date_parsed"
    t.jsonb "gedcom_raw_data"
    t.datetime "last_imported_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_families_on_deleted_at", where: "(deleted_at IS NULL)"
    t.index ["gedcom_id"], name: "index_families_on_gedcom_id", unique: true
    t.index ["gedcom_raw_data"], name: "index_families_on_gedcom_raw_data", using: :gin
    t.index ["last_imported_at"], name: "index_families_on_last_imported_at"
    t.index ["marriage_place_id"], name: "index_families_on_marriage_place_id"
  end

  create_table "family_members", primary_key: ["family_id", "individual_id", "role"], force: :cascade do |t|
    t.bigint "family_id", null: false
    t.bigint "individual_id", null: false
    t.string "role", limit: 20, null: false
    t.integer "child_order"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_family_members_on_deleted_at", where: "(deleted_at IS NULL)"
    t.index ["family_id", "child_order"], name: "index_family_members_on_family_id_and_child_order", where: "((role)::text = 'CHILD'::text)"
    t.index ["family_id", "role"], name: "index_family_members_on_family_id_and_role"
    t.index ["individual_id"], name: "index_family_members_on_individual_id"
    t.check_constraint "role::text = ANY (ARRAY['FATHER'::character varying, 'MOTHER'::character varying, 'CHILD'::character varying]::text[])", name: "chk_role"
  end

  create_table "individual_events", force: :cascade do |t|
    t.bigint "individual_id", null: false
    t.string "event_type", limit: 50, null: false
    t.string "date_string"
    t.datetime "date_parsed"
    t.bigint "place_id"
    t.text "description"
    t.jsonb "gedcom_raw_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date_parsed"], name: "index_individual_events_on_date_parsed"
    t.index ["gedcom_raw_data"], name: "index_individual_events_on_gedcom_raw_data", using: :gin
    t.index ["individual_id", "event_type"], name: "index_individual_events_on_individual_id_and_event_type"
    t.index ["place_id"], name: "index_individual_events_on_place_id"
  end

  create_table "individuals", force: :cascade do |t|
    t.string "gedcom_id", limit: 50
    t.string "given_name"
    t.string "surname"
    t.string "sex", limit: 1
    t.boolean "is_tree_root", default: false, null: false
    t.jsonb "gedcom_raw_data"
    t.datetime "last_imported_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "to_tsvector('english'::regconfig, (((COALESCE(given_name, ''::character varying))::text || ' '::text) || (COALESCE(surname, ''::character varying))::text))", name: "idx_individuals_name_search", using: :gin
    t.index ["deleted_at"], name: "index_individuals_on_deleted_at", where: "(deleted_at IS NULL)"
    t.index ["gedcom_id"], name: "index_individuals_on_gedcom_id", unique: true
    t.index ["gedcom_raw_data"], name: "index_individuals_on_gedcom_raw_data", using: :gin
    t.index ["is_tree_root"], name: "index_individuals_on_is_tree_root", where: "(is_tree_root = true)"
    t.index ["last_imported_at"], name: "index_individuals_on_last_imported_at"
    t.index ["surname"], name: "index_individuals_on_surname"
  end

  create_table "places", force: :cascade do |t|
    t.string "name", limit: 500, null: false
    t.string "normalized_name", limit: 500
    t.string "city"
    t.string "state_province"
    t.string "country"
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.jsonb "gedcom_raw_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "to_tsvector('english'::regconfig, (name)::text)", name: "idx_places_search", using: :gin
    t.index ["city"], name: "index_places_on_city"
    t.index ["country"], name: "index_places_on_country"
    t.index ["gedcom_raw_data"], name: "index_places_on_gedcom_raw_data", using: :gin
    t.index ["normalized_name"], name: "index_places_on_normalized_name"
  end

  create_table "transcriptions", force: :cascade do |t|
    t.bigint "artifact_id", null: false
    t.text "transcription_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_id"], name: "index_transcriptions_on_artifact_id"
  end

  create_table "translations", force: :cascade do |t|
    t.bigint "transcription_id", null: false
    t.text "translated_text", null: false
    t.string "target_language", limit: 10, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["transcription_id"], name: "index_translations_on_transcription_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "annotations", "artifact_files", on_delete: :cascade
  add_foreign_key "artifact_files", "artifacts", on_delete: :cascade
  add_foreign_key "commentaries", "artifacts", on_delete: :cascade
  add_foreign_key "families", "places", column: "marriage_place_id", on_delete: :nullify
  add_foreign_key "family_members", "families", on_delete: :cascade
  add_foreign_key "family_members", "individuals", on_delete: :cascade
  add_foreign_key "individual_events", "individuals", on_delete: :cascade
  add_foreign_key "individual_events", "places", on_delete: :nullify
  add_foreign_key "transcriptions", "artifacts", on_delete: :cascade
  add_foreign_key "translations", "transcriptions", on_delete: :cascade
end
