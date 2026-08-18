# Shared response shapes for the family-tree API. Keys are camelCase because
# the payloads are a contract with the family-tree island, ported unchanged
# from the AdonisJS app.
module FamilyTree
  PRIMARY_SURNAME = "Marias"

  module_function

  def empty_relationship_metadata
    {
      childFamilyIds: [],
      spouseFamilyIds: [],
      hasUnloadedAncestors: false,
      hasUnloadedDescendants: false,
      hasUnloadedSiblings: false
    }
  end

  # Build an individual payload from a loaded Individual (events must be loaded).
  def individual_response(individual, relationships = empty_relationship_metadata)
    birth = individual.events.find { |event| event.event_type == "BIRTH" }
    death = individual.events.find { |event| event.event_type == "DEATH" }
    {
      id: individual.id,
      givenName: individual.given_name,
      surname: individual.surname,
      sex: individual.sex,
      birthDate: birth&.date_string,
      birthPlace: birth&.place&.name,
      deathDate: death&.date_string,
      deathPlace: death&.place&.name,
      relationships: relationships
    }
  end
end
