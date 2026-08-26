module FamilyTree
  # Per-individual relationship metadata for a tree response, in one query.
  #
  # The recursive CTEs in Individual::Queries decide *who* is in the tree. This
  # answers a different question about the result: for each loaded individual,
  # what is one hop away, and is any of it outside the set we are returning?
  # The frontend uses the `hasUnloaded*` flags to decide where to draw expand
  # arrows, so they are relative to this response, not absolute.
  module Metadata
    METADATA_SQL = <<~SQL.freeze
      WITH member_families AS (
          SELECT fm.individual_id, fm.family_id, fm.role
          FROM family_members fm
          WHERE fm.individual_id IN (:loaded_ids)
            AND fm.deleted_at IS NULL
      ),
      relatives AS (
          SELECT mf.individual_id,
                 mf.role AS own_role,
                 mf.family_id,
                 other.individual_id AS relative_id,
                 other.role AS relative_role
          FROM member_families mf
          INNER JOIN family_members other
                  ON other.family_id = mf.family_id
                 AND other.deleted_at IS NULL
      )
      SELECT
          r.individual_id,
          JSON_AGG(DISTINCT r.family_id) FILTER (WHERE r.own_role = 'CHILD')
              AS child_family_ids,
          JSON_AGG(DISTINCT r.family_id) FILTER (WHERE r.own_role IN ('FATHER', 'MOTHER'))
              AS spouse_family_ids,
          COALESCE(BOOL_OR(
              r.own_role = 'CHILD'
              AND r.relative_role IN ('FATHER', 'MOTHER')
              AND r.relative_id NOT IN (:loaded_ids)
          ), FALSE) AS has_unloaded_ancestors,
          COALESCE(BOOL_OR(
              r.own_role IN ('FATHER', 'MOTHER')
              AND r.relative_role = 'CHILD'
              AND r.relative_id NOT IN (:loaded_ids)
          ), FALSE) AS has_unloaded_descendants,
          COALESCE(BOOL_OR(
              r.own_role = 'CHILD'
              AND r.relative_role = 'CHILD'
              AND r.relative_id <> r.individual_id
              AND r.relative_id NOT IN (:loaded_ids)
          ), FALSE) AS has_unloaded_siblings
      FROM relatives r
      GROUP BY r.individual_id
    SQL

    module_function

    def relationship_metadata_for(loaded_ids)
      return {} if loaded_ids.empty?

      sql = ActiveRecord::Base.sanitize_sql_array([ METADATA_SQL, { loaded_ids: } ])
      rows = ActiveRecord::Base.connection.select_all(sql)

      # select_all does not type-cast aggregate columns, so ids arrive as JSON
      # strings and booleans arrive driver-dependent; both are normalized here.
      metadata = rows.to_a.to_h do |row|
        [ row["individual_id"].to_i, {
          childFamilyIds: id_list(row["child_family_ids"]),
          spouseFamilyIds: id_list(row["spouse_family_ids"]),
          hasUnloadedAncestors: bool(row["has_unloaded_ancestors"]),
          hasUnloadedDescendants: bool(row["has_unloaded_descendants"]),
          hasUnloadedSiblings: bool(row["has_unloaded_siblings"])
        } ]
      end

      # An individual with no memberships produces no rows, but still needs an entry.
      loaded_ids.index_with { |id| metadata[id] || FamilyTree.empty_relationship_metadata }
    end

    def id_list(value)
      list = value.is_a?(String) ? JSON.parse(value) : (value || [])
      list.map(&:to_i).sort
    end

    def bool(value)
      ActiveModel::Type::Boolean.new.cast(value) == true
    end

    # Events for every loaded individual in one query, with their places.
    def events_by_individual(loaded_ids)
      return {} if loaded_ids.empty?

      IndividualEvent.where(individual_id: loaded_ids)
        .includes(:place)
        .group_by(&:individual_id)
    end
  end
end
