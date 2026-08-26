# Creates and updates individuals from the tree island's form payloads, keeping
# their single BIRTH/DEATH events in sync, and guards deletion.
class Individual::Editor
  MAX_DESCENDANT_GENERATIONS = 10

  def create_from_request(data)
    gedcom_id = data[:gedcomId].presence || Gedcom::Ids.next_individual_id
    if Individual.exists?(gedcom_id: gedcom_id)
      raise ConflictError.new("Individual with GEDCOM ID '#{gedcom_id}' already exists",
        field: "gedcomId")
    end

    individual = Individual.create!(
      gedcom_id: gedcom_id,
      given_name: data[:givenName].presence,
      surname: data[:surname].presence,
      sex: data[:sex].presence&.first,
      is_tree_root: false
    )

    sync_events(individual, data)
    response_for(individual)
  end

  def update_from_request(id, data)
    individual = Individual.find_by(id: id)
    raise NotFoundError, "Individual with ID #{id} not found" unless individual

    individual.update!(
      given_name: data[:givenName].presence,
      surname: data[:surname].presence,
      sex: data[:sex].presence&.first
    )

    sync_events(individual, data)
    response_for(individual)
  end

  def soft_delete(id)
    individual = Individual.find_by(id: id)
    return false unless individual

    validation = can_delete(id)
    raise ConflictError, validation[:reason] || "Cannot delete individual" unless validation[:valid]

    individual.destroy
    true
  end

  def can_delete(id)
    individual = Individual.find_by(id: id)
    return { valid: false, reason: "Individual not found" } unless individual

    child_count = children_of_spouse_families(id)
    if child_count.positive?
      suffix = child_count > 1 ? "children" : "child"
      return { valid: false, reason: "Cannot delete: individual has #{child_count} #{suffix}" }
    end

    # The recursive query's anchor row is the person themselves, so they always
    # appear in the result and must be excluded.
    descendants = Individual::Queries.descendants(id, MAX_DESCENDANT_GENERATIONS)
      .reject { |d| d.id == id }
    if descendants.any?
      return { valid: false,
               reason: "Cannot delete: individual has #{descendants.size} descendant(s)" }
    end

    { valid: true, reason: nil }
  end

  private

  def children_of_spouse_families(individual_id)
    family_ids = FamilyMember.parents.where(individual_id: individual_id).pluck(:family_id)
    return 0 if family_ids.empty?

    FamilyMember.children.where(family_id: family_ids).count
  end

  def response_for(individual)
    individual.events.reset
    FamilyTree.individual_response(individual)
  end

  def sync_events(individual, data)
    upsert_event(individual, "BIRTH", data[:birthDate].presence, data[:birthPlace].presence)
    upsert_event(individual, "DEATH", data[:deathDate].presence, data[:deathPlace].presence)
  end

  # Create/update/clear the single event of a type for an individual.
  def upsert_event(individual, event_type, date_string, place_name)
    existing = individual.events.where(event_type: event_type).order(:id).to_a

    if date_string.nil? && place_name.nil?
      existing.each(&:destroy!)
      return
    end

    place = Place.find_or_create_named(place_name)
    if existing.empty?
      individual.events.create!(event_type:, date_string:, place_id: place&.id)
      return
    end

    first, *rest = existing
    first.update!(date_string: date_string, place_id: place&.id)
    rest.each(&:destroy!)
  end
end
