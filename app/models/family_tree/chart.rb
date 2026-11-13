module FamilyTree
  # One chart page: the island's initial tree plus the expansions named in the
  # URL (`up[]`, `down[]`), merged the way the island's store merges them, then
  # laid out. The Builder is used as is; this only composes its responses and
  # puts parents and children in the order the layout reads as meaning.
  class Chart
    Card = Data.define(:person, :position, :expands_up, :expands_down) do
      alias_method :expands_up?, :expands_up
      alias_method :expands_down?, :expands_down
    end

    def initialize(up: [], down: [], builder: Builder.new)
      @up = Array(up).map(&:to_i).uniq
      @down = Array(down).map(&:to_i).uniq
      @builder = builder
    end

    # An expand button shows where relatives exist beyond the chart and none
    # are drawn yet, as the island decides it.
    def cards
      @cards ||= people.values.map do |person|
        id = person[:id]
        Card.new(
          person:,
          position: layout.positions.fetch(id),
          expands_up: person[:relationships][:hasUnloadedAncestors] && !with_parents.include?(id),
          expands_down: person[:relationships][:hasUnloadedDescendants] && !with_children.include?(id)
        )
      end
    end

    def units
      @units ||= families.values.sort_by { |family| family[:familyId] }.map do |family|
        Layout::Unit.new(id: family[:familyId],
          parent_ids: fathers_first(family[:parentIds]),
          child_ids: birth_order(family[:familyId], family[:childIds]))
      end
    end

    def layout
      @layout ||= Layout.new(individual_ids: people.keys, units:)
    end

    private

    def people = tree.first
    def families = tree.last

    # Expansions apply once their person is on the chart, whichever array they
    # came from, so a link's order of clicks replays and a stale or forged id
    # cannot pull in strangers.
    def tree
      @tree ||= begin
        people = {}
        families = {}
        merge(people, families, @builder.initial_tree)
        pending = @up.map { |id| [ id, :up ] } + @down.map { |id| [ id, :down ] }
        loop do
          ready, pending = pending.partition { |id, _| people.key?(id) }
          break if ready.empty?
          ready.each { |id, direction| merge(people, families, expand(id, direction, people)) }
        end
        [ people, families ]
      end
    end

    # `known` is the chart so far: the root's own record came with an earlier
    # response, and `people` is not available while the tree is being built.
    def expand(id, direction, known)
      case direction
      when :up then ancestors_only(@builder.expand_tree(id, generations_up: 1, include_siblings: true), id, known)
      when :down then @builder.expand_tree(id, generations_down: 1)
      end
    end

    # An up-expansion as the island showed it: the parents (and their other
    # marriages), the siblings, and only those siblings' marriages that have
    # children. A childless in-law would float beside a sibling with nothing
    # attaching them; the siblings' descendants are a down-expansion away.
    def ancestors_only(response, root_id, known)
      individuals = response[:individuals].index_by { |person| person[:id] }
      families = response[:families].index_by { |family| family[:familyId] }
      root = known[root_id] || individuals[root_id]
      parent_family = families[root&.dig(:relationships, :childFamilyIds)&.first]
      return response unless parent_family

      keep_people = Set.new(parent_family[:parentIds] + parent_family[:childIds])
      keep_families = Set[parent_family[:familyId]]
      parent_family[:parentIds].each { |id| keep_families.merge(individuals.dig(id, :relationships, :spouseFamilyIds) || []) }
      parent_family[:childIds].each do |id|
        (individuals.dig(id, :relationships, :spouseFamilyIds) || []).each do |family_id|
          marriage = families[family_id]
          next unless marriage && marriage[:childIds].any?
          keep_families << family_id
          keep_people.merge(marriage[:parentIds])
        end
      end

      { individuals: response[:individuals].select { |person| keep_people.include?(person[:id]) },
        families: response[:families].select { |family| keep_families.include?(family[:familyId]) } }
    end

    def merge(people, families, response)
      response[:individuals].each { |person| people[person[:id]] ||= person }
      response[:families].each do |family|
        known = families[family[:familyId]]
        families[family[:familyId]] = known ? {
          familyId: family[:familyId],
          parentIds: known[:parentIds] | family[:parentIds],
          childIds: known[:childIds] | family[:childIds]
        } : family
      end
    end

    # Men left; when sex cannot decide (unknown, or a same-sex couple), the
    # lower id, so the order never depends on how the rows came back.
    def fathers_first(parent_ids)
      parent_ids.sort_by { |id| [ people[id][:sex] == "M" ? 0 : 1, id ] }
    end

    def birth_order(family_id, child_ids)
      child_ids.sort_by { |id| [ child_orders.fetch([ family_id, id ], Float::INFINITY), id ] }
    end

    def child_orders
      @child_orders ||= FamilyMember.children.where(family_id: families.keys)
        .pluck(:family_id, :individual_id, :child_order)
        .to_h { |family_id, individual_id, order| [ [ family_id, individual_id ], order || Float::INFINITY ] }
    end

    def with_parents
      @with_parents ||= units.select { |unit| unit.parent_ids.any? }.flat_map(&:child_ids).to_set
    end

    def with_children
      @with_children ||= units.select { |unit| unit.child_ids.any? }.flat_map(&:parent_ids).to_set
    end
  end
end
