module FamilyTree
  # Relationship edits from the tree island: add child/spouse/parent/sibling,
  # link an existing parent. Each returns the local tree context around the
  # records it touched.
  class Mutations
    def initialize(tree: Builder.new)
      @tree = tree
    end

    def add_child(parent_id:, child_data:, parent_family_id: nil)
      parent = Individual.find_by(id: parent_id)
      raise NotFoundError, "Parent with ID #{parent_id} not found" unless parent

      child = create_individual(child_data)

      family =
        if parent_family_id.present?
          Family.find_by(id: parent_family_id) ||
            raise(NotFoundError, "Family with ID #{parent_family_id} not found")
        else
          Family.create!(gedcom_id: Gedcom::Ids.next_family_id).tap do |created|
            FamilyMember.create!(family_id: created.id, individual_id: parent.id,
              role: parent_role(parent))
          end
        end

      FamilyMember.create!(family_id: family.id, individual_id: child.id, role: "CHILD",
        child_order: next_child_order(family.id))

      @tree.tree_response_for_individuals([ parent.id, child.id ])
    end

    def add_spouse(person_id:, spouse_data:, marriage_data: nil)
      person = Individual.find_by(id: person_id)
      raise NotFoundError, "Person with ID #{person_id} not found" unless person

      spouse = create_individual(spouse_data)

      family = Family.create!(
        gedcom_id: Gedcom::Ids.next_family_id,
        marriage_date_string: marriage_data&.dig(:marriageDateString),
        divorce_date_string: marriage_data&.dig(:divorceDateString)
      )
      FamilyMember.create!(family_id: family.id, individual_id: person.id,
        role: parent_role(person))
      FamilyMember.create!(family_id: family.id, individual_id: spouse.id,
        role: parent_role(spouse))

      @tree.tree_response_for_individuals([ person.id, spouse.id ])
    end

    def add_parent(child_id:, role:, parent_data:)
      child = Individual.find_by(id: child_id)
      raise NotFoundError, "Child with ID #{child_id} not found" unless child
      raise InvalidArgumentError, "Role must be FATHER or MOTHER" unless parent_role?(role)

      parent = create_individual(parent_data)
      family = resolve_child_family(child.id, role)
      FamilyMember.create!(family_id: family.id, individual_id: parent.id, role: role)

      @tree.tree_response_for_individuals([ parent.id ])
    end

    def link_existing_parent(child_id:, existing_parent_id:, role:)
      child = Individual.find_by(id: child_id)
      raise NotFoundError, "Child with ID #{child_id} not found" unless child
      existing_parent = Individual.find_by(id: existing_parent_id)
      unless existing_parent
        raise NotFoundError, "Parent with ID #{existing_parent_id} not found"
      end
      unless parent_role?(role)
        raise InvalidArgumentError, "Invalid role: #{role}. Must be FATHER or MOTHER"
      end

      family = resolve_child_family(child.id, role)
      if FamilyMember.exists?(family_id: family.id, individual_id: existing_parent.id)
        raise ConflictError, "This person is already a member of the child's family"
      end
      FamilyMember.create!(family_id: family.id, individual_id: existing_parent.id, role: role)

      @tree.tree_response_for_individuals([ child.id, existing_parent.id ])
    end

    def add_sibling(person_id:, sibling_data:)
      person = Individual.find_by(id: person_id)
      raise NotFoundError, "Person with ID #{person_id} not found" unless person

      parent_family_id = FamilyMember.children.where(individual_id: person.id)
        .pick(:family_id)
      unless parent_family_id
        raise ConflictError, "Person has no parent family - cannot add sibling"
      end

      sibling = create_individual(sibling_data)
      FamilyMember.create!(family_id: parent_family_id, individual_id: sibling.id,
        role: "CHILD", child_order: next_child_order(parent_family_id))

      @tree.tree_response_for_individuals([ person.id, sibling.id ])
    end

    private

    def create_individual(data)
      gedcom_id = data[:gedcomId].presence || Gedcom::Ids.next_individual_id
      if Individual.exists?(gedcom_id: gedcom_id)
        raise ConflictError.new("Individual with GEDCOM ID '#{gedcom_id}' already exists",
          field: "gedcomId")
      end
      Individual.create!(
        gedcom_id: gedcom_id,
        given_name: data[:givenName].presence,
        surname: data[:surname].presence,
        sex: data[:sex].presence&.first,
        is_tree_root: false
      )
    end

    def parent_role?(role)
      FamilyMember::PARENT_ROLES.include?(role)
    end

    def parent_role(individual)
      individual.sex == "F" ? "MOTHER" : "FATHER"
    end

    def next_child_order(family_id)
      (FamilyMember.children.where(family_id: family_id).maximum(:child_order) || -1) + 1
    end

    # Find or create the family in which `child_id` is a CHILD, validating the
    # new parent role.
    def resolve_child_family(child_id, role)
      family_id = FamilyMember.children.where(individual_id: child_id).pick(:family_id)

      if family_id.nil?
        family = Family.create!(gedcom_id: Gedcom::Ids.next_family_id)
        FamilyMember.create!(family_id: family.id, individual_id: child_id, role: "CHILD")
        return family
      end

      family = Family.find(family_id)
      parents = FamilyMember.parents.where(family_id: family.id)
      raise ConflictError, "Family already has 2 parents" if parents.count >= 2
      if parents.exists?(role: role)
        raise ConflictError, "#{role} already exists in family"
      end
      family
    end
  end
end
