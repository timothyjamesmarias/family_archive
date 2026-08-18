class CreateGenealogyTables < ActiveRecord::Migration[8.1]
  def change
    create_table :individuals do |t|
      t.string :gedcom_id, limit: 50
      t.string :given_name
      t.string :surname
      t.string :sex, limit: 1
      t.boolean :is_tree_root, null: false, default: false
      t.jsonb :gedcom_raw_data
      t.datetime :last_imported_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :individuals, :gedcom_id, unique: true
    add_index :individuals, :surname
    add_index :individuals, :last_imported_at
    add_index :individuals,
      "to_tsvector('english', COALESCE(given_name, '') || ' ' || COALESCE(surname, ''))",
      using: :gin, name: "idx_individuals_name_search"
    add_index :individuals, :gedcom_raw_data, using: :gin
    add_index :individuals, :is_tree_root, where: "is_tree_root = TRUE"
    add_index :individuals, :deleted_at, where: "deleted_at IS NULL"

    create_table :places do |t|
      t.string :name, limit: 500, null: false
      t.string :normalized_name, limit: 500
      t.string :city
      t.string :state_province
      t.string :country
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.jsonb :gedcom_raw_data
      t.timestamps
    end
    add_index :places, :normalized_name
    add_index :places, "to_tsvector('english', name)", using: :gin, name: "idx_places_search"
    add_index :places, :city
    add_index :places, :country
    add_index :places, :gedcom_raw_data, using: :gin

    create_table :families do |t|
      t.string :gedcom_id, limit: 50
      t.string :marriage_date_string
      t.datetime :marriage_date_parsed
      t.references :marriage_place, foreign_key: { to_table: :places, on_delete: :nullify }
      t.string :divorce_date_string
      t.datetime :divorce_date_parsed
      t.jsonb :gedcom_raw_data
      t.datetime :last_imported_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :families, :gedcom_id, unique: true
    add_index :families, :gedcom_raw_data, using: :gin
    add_index :families, :last_imported_at
    add_index :families, :deleted_at, where: "deleted_at IS NULL"

    create_table :family_members, primary_key: [ :family_id, :individual_id, :role ] do |t|
      t.bigint :family_id, null: false
      t.bigint :individual_id, null: false
      t.string :role, limit: 20, null: false
      t.integer :child_order
      t.datetime :created_at, null: false
      t.datetime :deleted_at
      t.check_constraint "role IN ('FATHER', 'MOTHER', 'CHILD')", name: "chk_role"
    end
    add_foreign_key :family_members, :families, on_delete: :cascade
    add_foreign_key :family_members, :individuals, on_delete: :cascade
    add_index :family_members, :individual_id
    add_index :family_members, [ :family_id, :role ]
    add_index :family_members, [ :family_id, :child_order ], where: "role = 'CHILD'"
    add_index :family_members, :deleted_at, where: "deleted_at IS NULL"

    create_table :individual_events do |t|
      t.references :individual, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :event_type, limit: 50, null: false
      t.string :date_string
      t.datetime :date_parsed
      t.references :place, foreign_key: { on_delete: :nullify }
      t.text :description
      t.jsonb :gedcom_raw_data
      t.timestamps
    end
    add_index :individual_events, [ :individual_id, :event_type ]
    add_index :individual_events, :date_parsed
    add_index :individual_events, :gedcom_raw_data, using: :gin
  end
end
