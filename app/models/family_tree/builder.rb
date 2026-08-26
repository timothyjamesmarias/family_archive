module FamilyTree
  # Assembles the `{ individuals:, families: }` payload the tree island renders.
  class Builder
    def root_individuals
      Individual::Queries.most_recent_generation_by_surname(PRIMARY_SURNAME)
    end

    def initial_tree
      build_tree_response(Individual.tree_roots.ids,
        generations_up: 1, generations_down: 0, include_siblings: true)
    end

    def expand_tree(person_id, generations_up: 0, generations_down: 0, include_siblings: false)
      build_tree_response([ person_id ], generations_up:, generations_down:, include_siblings:)
    end

    # Used by Mutations to render a mutation's local context: the given
    # individuals plus every member of every family they belong to.
    def tree_response_for_individuals(individual_ids)
      loaded = {}
      individual_ids.each do |id|
        individual = Individual.find_by(id: id)
        loaded[individual.id] = individual if individual

        member_ids = FamilyMember.where(individual_id: id).pluck(:family_id)
        FamilyMember.where(family_id: member_ids).find_each do |member|
          next if loaded.key?(member.individual_id)

          relative = Individual.find_by(id: member.individual_id)
          loaded[relative.id] = relative if relative
        end
      end

      families = build_family_units(loaded.keys)
      events = Metadata.events_by_individual(loaded.keys)

      individuals = loaded.values.map do |individual|
        individual.association(:events).target = events[individual.id] || []
        FamilyTree.individual_response(individual)
      end

      { individuals:, families: }
    end

    private

    def build_tree_response(root_ids, generations_up:, generations_down:, include_siblings:)
      loaded = {}

      root_ids.each do |root_id|
        root = Individual.find_by(id: root_id)
        loaded[root.id] = root if root
        if generations_up.positive?
          Individual::Queries.ancestors(root_id, generations_up).each { |a| loaded[a.id] = a }
        end
        if generations_down.positive?
          Individual::Queries.descendants(root_id, generations_down).each { |d| loaded[d.id] = d }
        end
        if include_siblings
          Individual::Queries.siblings(root_id).each { |s| loaded[s.id] = s }
        end
      end

      # Snapshot before loading relatives: spouses and siblings pulled in here
      # are not themselves re-processed, so the frontier stays one hop wide.
      load_relatives(loaded.keys, loaded)

      loaded_ids = loaded.keys
      families = build_family_units(loaded_ids)
      events = Metadata.events_by_individual(loaded_ids)
      metadata = Metadata.relationship_metadata_for(loaded_ids)

      individuals = loaded.values.map do |individual|
        individual.association(:events).target = events[individual.id] || []
        FamilyTree.individual_response(
          individual, metadata[individual.id] || FamilyTree.empty_relationship_metadata
        )
      end

      { individuals:, families: }
    end

    # Widen the set by one hop: first the spouses of everyone in the snapshot,
    # then the siblings of anyone whose parent is present.
    #
    # The two passes run in sequence, not together: the sibling pass tests
    # "is a parent of this family loaded?" against a set that already includes
    # the spouses. Computing both from the pre-pass state finds strictly fewer
    # people.
    def load_relatives(snapshot, loaded)
      return if snapshot.empty?

      memberships = FamilyMember.where(individual_id: snapshot).to_a
      family_ids = memberships.map(&:family_id).uniq
      return if family_ids.empty?

      members_by_family = FamilyMember.where(family_id: family_ids).group_by(&:family_id)
      memberships_by_individual = memberships.group_by(&:individual_id)

      spouse_ids = snapshot.flat_map do |individual_id|
        (memberships_by_individual[individual_id] || [])
          .select(&:parent_role?)
          .flat_map { |membership| members_by_family[membership.family_id] || [] }
          .select { |member| member.parent_role? && member.individual_id != individual_id }
          .map(&:individual_id)
      end
      add_missing(spouse_ids, loaded)

      sibling_ids = snapshot.flat_map do |individual_id|
        (memberships_by_individual[individual_id] || [])
          .select { |membership| membership.role == "CHILD" }
          .flat_map do |membership|
            members = members_by_family[membership.family_id] || []
            parent_loaded = members.any? { |m| m.parent_role? && loaded.key?(m.individual_id) }
            parent_loaded ? members.select { |m| m.role == "CHILD" }.map(&:individual_id) : []
          end
      end
      add_missing(sibling_ids, loaded)
    end

    # Insertion order follows the candidate order, not the query's.
    def add_missing(candidate_ids, loaded)
      missing = candidate_ids.uniq.reject { |id| loaded.key?(id) }
      return if missing.empty?

      by_id = Individual.where(id: missing).index_by(&:id)
      missing.each do |id|
        individual = by_id[id]
        loaded[individual.id] = individual if individual
      end
    end

    # Two queries: the memberships of the loaded people, then every member of
    # the families those memberships name. Family order follows the loaded set.
    def build_family_units(loaded_ids)
      return [] if loaded_ids.empty?

      memberships = FamilyMember.where(individual_id: loaded_ids).to_a
      family_ids = ordered_family_ids(loaded_ids, memberships)
      return [] if family_ids.empty?

      loaded_set = loaded_ids.to_set
      members_by_family = FamilyMember.where(family_id: family_ids).group_by(&:family_id)

      family_ids.filter_map do |family_id|
        members = members_by_family[family_id] || []
        parent_ids = members
          .select { |m| m.parent_role? && loaded_set.include?(m.individual_id) }
          .map(&:individual_id)
        child_ids = members
          .select { |m| m.role == "CHILD" && loaded_set.include?(m.individual_id) }
          .map(&:individual_id)

        { familyId: family_id, parentIds: parent_ids, childIds: child_ids } if
          parent_ids.any? || child_ids.any?
      end
    end

    # Families in the order their first loaded member appears, matching the
    # traversal order a per-individual loop would produce.
    def ordered_family_ids(individual_ids, memberships)
      by_individual = memberships.group_by(&:individual_id)
      individual_ids
        .flat_map { |id| (by_individual[id] || []).map(&:family_id) }
        .uniq
    end
  end
end
