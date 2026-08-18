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

ActiveRecord::Schema[8.1].define(version: 2026_08_17_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "annotations", force: :cascade do |t|
    t.text "annotation_text", null: false
    t.bigint "artifact_file_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "x_coord", precision: 10, scale: 6
    t.decimal "y_coord", precision: 10, scale: 6
    t.index ["artifact_file_id"], name: "index_annotations_on_artifact_file_id"
  end

  create_table "articles", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "excerpt", limit: 1000
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "title", limit: 500, null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
  end

  create_table "artifact_files", force: :cascade do |t|
    t.bigint "artifact_id", null: false
    t.datetime "created_at", null: false
    t.integer "file_sequence", null: false
    t.bigint "file_size", null: false
    t.string "mime_type", null: false
    t.string "storage_path", limit: 1000, null: false
    t.string "thumbnail_path", limit: 1000
    t.string "thumbnail_size", limit: 50
    t.datetime "updated_at", null: false
    t.datetime "uploaded_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["artifact_id", "file_sequence"], name: "index_artifact_files_on_artifact_id_and_file_sequence", unique: true
    t.index ["artifact_id"], name: "index_artifact_files_on_artifact_id"
  end

  create_table "artifacts", force: :cascade do |t|
    t.string "artifact_type", limit: 50, null: false
    t.datetime "created_at", null: false
    t.bigint "file_size", null: false
    t.string "mime_type", null: false
    t.string "original_date_string"
    t.string "slug", null: false
    t.string "storage_path", limit: 1000, null: false
    t.string "title", limit: 500
    t.datetime "updated_at", null: false
    t.datetime "uploaded_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
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

  create_table "families", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "divorce_date_parsed"
    t.string "divorce_date_string"
    t.string "gedcom_id", limit: 50
    t.jsonb "gedcom_raw_data"
    t.datetime "last_imported_at"
    t.datetime "marriage_date_parsed"
    t.string "marriage_date_string"
    t.bigint "marriage_place_id"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_families_on_deleted_at", where: "(deleted_at IS NULL)"
    t.index ["gedcom_id"], name: "index_families_on_gedcom_id", unique: true
    t.index ["gedcom_raw_data"], name: "index_families_on_gedcom_raw_data", using: :gin
    t.index ["last_imported_at"], name: "index_families_on_last_imported_at"
    t.index ["marriage_place_id"], name: "index_families_on_marriage_place_id"
  end

  create_table "family_members", primary_key: ["family_id", "individual_id", "role"], force: :cascade do |t|
    t.integer "child_order"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "family_id", null: false
    t.bigint "individual_id", null: false
    t.string "role", limit: 20, null: false
    t.index ["deleted_at"], name: "index_family_members_on_deleted_at", where: "(deleted_at IS NULL)"
    t.index ["family_id", "child_order"], name: "index_family_members_on_family_id_and_child_order", where: "((role)::text = 'CHILD'::text)"
    t.index ["family_id", "role"], name: "index_family_members_on_family_id_and_role"
    t.index ["individual_id"], name: "index_family_members_on_individual_id"
    t.check_constraint "role::text = ANY (ARRAY['FATHER'::character varying, 'MOTHER'::character varying, 'CHILD'::character varying]::text[])", name: "chk_role"
  end

  create_table "individual_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "date_parsed"
    t.string "date_string"
    t.text "description"
    t.string "event_type", limit: 50, null: false
    t.jsonb "gedcom_raw_data"
    t.bigint "individual_id", null: false
    t.bigint "place_id"
    t.datetime "updated_at", null: false
    t.index ["date_parsed"], name: "index_individual_events_on_date_parsed"
    t.index ["gedcom_raw_data"], name: "index_individual_events_on_gedcom_raw_data", using: :gin
    t.index ["individual_id", "event_type"], name: "index_individual_events_on_individual_id_and_event_type"
    t.index ["place_id"], name: "index_individual_events_on_place_id"
  end

  create_table "individuals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "gedcom_id", limit: 50
    t.jsonb "gedcom_raw_data"
    t.string "given_name"
    t.boolean "is_tree_root", default: false, null: false
    t.datetime "last_imported_at"
    t.string "sex", limit: 1
    t.string "surname"
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
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.jsonb "gedcom_raw_data"
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.string "name", limit: 500, null: false
    t.string "normalized_name", limit: 500
    t.string "state_province"
    t.datetime "updated_at", null: false
    t.index "to_tsvector('english'::regconfig, (name)::text)", name: "idx_places_search", using: :gin
    t.index ["city"], name: "index_places_on_city"
    t.index ["country"], name: "index_places_on_country"
    t.index ["gedcom_raw_data"], name: "index_places_on_gedcom_raw_data", using: :gin
    t.index ["normalized_name"], name: "index_places_on_normalized_name"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "transcriptions", force: :cascade do |t|
    t.bigint "artifact_id", null: false
    t.datetime "created_at", null: false
    t.text "transcription_text", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_id"], name: "index_transcriptions_on_artifact_id"
  end

  create_table "translations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "target_language", limit: 10, null: false
    t.bigint "transcription_id", null: false
    t.text "translated_text", null: false
    t.datetime "updated_at", null: false
    t.index ["transcription_id"], name: "index_translations_on_transcription_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "annotations", "artifact_files", on_delete: :cascade
  add_foreign_key "artifact_files", "artifacts", on_delete: :cascade
  add_foreign_key "commentaries", "artifacts", on_delete: :cascade
  add_foreign_key "families", "places", column: "marriage_place_id", on_delete: :nullify
  add_foreign_key "family_members", "families", on_delete: :cascade
  add_foreign_key "family_members", "individuals", on_delete: :cascade
  add_foreign_key "individual_events", "individuals", on_delete: :cascade
  add_foreign_key "individual_events", "places", on_delete: :nullify
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "transcriptions", "artifacts", on_delete: :cascade
  add_foreign_key "translations", "transcriptions", on_delete: :cascade
end
