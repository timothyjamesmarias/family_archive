# Recursive-CTE traversals over individuals/family_members. Kept as SQL strings
# executed through ActiveRecord: the queries walk parent/child edges to a
# bounded depth, which Active Record cannot express.
module Individual::Queries
  INDIVIDUAL_COLUMNS = <<~SQL.squish.freeze
    i.id, i.gedcom_id, i.given_name, i.surname, i.sex, i.is_tree_root,
    i.gedcom_raw_data, i.created_at, i.updated_at, i.last_imported_at, i.deleted_at
  SQL

  ANCESTORS_SQL = <<~SQL.freeze
    WITH RECURSIVE ancestors AS (
        SELECT #{INDIVIDUAL_COLUMNS}, 0 AS generation
        FROM individuals i
        WHERE i.id = :person_id AND i.deleted_at IS NULL
        UNION ALL
        SELECT #{INDIVIDUAL_COLUMNS}, a.generation + 1
        FROM individuals i
        INNER JOIN family_members fm ON fm.individual_id = i.id AND fm.deleted_at IS NULL
        INNER JOIN family_members fm_child ON fm_child.family_id = fm.family_id AND fm_child.deleted_at IS NULL
        INNER JOIN ancestors a ON a.id = fm_child.individual_id
        WHERE fm.role IN ('FATHER', 'MOTHER') AND fm_child.role = 'CHILD'
          AND i.deleted_at IS NULL AND a.generation < :max_generations
    )
    SELECT * FROM ancestors WHERE deleted_at IS NULL ORDER BY generation, id
  SQL

  DESCENDANTS_SQL = <<~SQL.freeze
    WITH RECURSIVE descendants AS (
        SELECT #{INDIVIDUAL_COLUMNS}, 0 AS generation
        FROM individuals i
        WHERE i.id = :person_id AND i.deleted_at IS NULL
        UNION ALL
        SELECT #{INDIVIDUAL_COLUMNS}, d.generation + 1
        FROM individuals i
        INNER JOIN family_members fm ON fm.individual_id = i.id AND fm.deleted_at IS NULL
        INNER JOIN family_members fm_parent ON fm_parent.family_id = fm.family_id AND fm_parent.deleted_at IS NULL
        INNER JOIN descendants d ON d.id = fm_parent.individual_id
        WHERE fm.role = 'CHILD' AND fm_parent.role IN ('FATHER', 'MOTHER')
          AND i.deleted_at IS NULL AND d.generation < :max_generations
    )
    SELECT * FROM descendants WHERE deleted_at IS NULL ORDER BY generation, id
  SQL

  SIBLINGS_SQL = <<~SQL.freeze
    SELECT DISTINCT #{INDIVIDUAL_COLUMNS}
    FROM individuals i
    INNER JOIN family_members fm ON fm.individual_id = i.id AND fm.deleted_at IS NULL
    WHERE fm.family_id IN (
        SELECT fm2.family_id FROM family_members fm2
        WHERE fm2.individual_id = :person_id AND fm2.role = 'CHILD' AND fm2.deleted_at IS NULL
    )
    AND fm.role = 'CHILD' AND i.id != :person_id AND i.deleted_at IS NULL
  SQL

  # Root-node discovery: people with the surname who are not a parent anywhere.
  MOST_RECENT_GENERATION_SQL = <<~SQL.freeze
    SELECT DISTINCT #{INDIVIDUAL_COLUMNS}
    FROM individuals i
    WHERE i.surname = :surname AND i.deleted_at IS NULL
    AND NOT EXISTS (
        SELECT 1 FROM family_members fm2
        WHERE fm2.individual_id = i.id AND fm2.role IN ('FATHER', 'MOTHER') AND fm2.deleted_at IS NULL
    )
    ORDER BY i.id
  SQL

  module_function

  # Ancestors up to max_generations, including the root at generation 0.
  def ancestors(person_id, max_generations)
    Individual.find_by_sql([ ANCESTORS_SQL, { person_id:, max_generations: } ])
  end

  # Descendants up to max_generations, including the root at generation 0.
  def descendants(person_id, max_generations)
    Individual.find_by_sql([ DESCENDANTS_SQL, { person_id:, max_generations: } ])
  end

  def siblings(person_id)
    Individual.find_by_sql([ SIBLINGS_SQL, { person_id: } ])
  end

  def most_recent_generation_by_surname(surname)
    Individual.find_by_sql([ MOST_RECENT_GENERATION_SQL, { surname: } ])
  end
end
