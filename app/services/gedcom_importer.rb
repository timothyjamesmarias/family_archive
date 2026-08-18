# Imports a GEDCOM file: upserts individuals and families by their GEDCOM id,
# links family members, and replaces the events the file describes. Runs in a
# single transaction — any failure rolls back every write.
class GedcomImporter
  # Event types this importer creates. Re-import replaces only these, so
  # events an archivist added by hand — MARRIAGE, OCCUPATION, RESIDENCE and
  # the rest — survive re-importing the same file.
  EVENT_TAGS = {
    "BIRT" => "BIRTH",
    "DEAT" => "DEATH",
    "BAPM" => "BAPTISM",
    "BURI" => "BURIAL"
  }.freeze
  IMPORTED_EVENT_TYPES = EVENT_TAGS.values.freeze

  def import_file(path)
    records = GedcomReader.read(path)
    individuals = records.select { |record| record.tag == "INDI" && record.pointer }
    families = records.select { |record| record.tag == "FAM" && record.pointer }

    ApplicationRecord.transaction do
      places_imported = import_places(individuals, families)
      individuals_imported = import_individuals(individuals)
      families_imported = import_families(families)
      events_imported = import_events(individuals)

      {
        success: true,
        individuals_imported: individuals_imported,
        families_imported: families_imported,
        events_imported: events_imported,
        places_imported: places_imported,
        warnings: [],
        errors: []
      }
    end
  end

  private

  def import_places(individuals, families)
    names = individuals.flat_map do |indi|
      EVENT_TAGS.keys.flat_map { |tag| indi.all(tag).map { |event| event.child_value("PLAC") } }
    end
    names += families.map { |fam| fam.child("MARR")&.child_value("PLAC") }

    names.compact_blank.uniq.count do |name|
      next false if Place.exists?(normalized_name: Place.normalize(name))

      Place.find_or_create_named(name)
      true
    end
  end

  def import_individuals(individuals)
    individuals.each do |indi|
      given, surname = parse_name(indi.child_value("NAME"))

      # with_deleted: the unique index spans soft-deleted rows, so an upsert
      # that cannot see them would crash on a re-imported deleted person.
      # Their deleted_at is left untouched — deleting in the tree is archivist
      # intent the file does not override.
      individual = Individual.with_deleted.find_or_initialize_by(gedcom_id: indi.pointer)
      individual.update!(
        given_name: given,
        surname: surname,
        sex: indi.child_value("SEX")&.first,
        gedcom_raw_data: { "children" => [ indi.to_raw ] },
        last_imported_at: Time.current
      )
    end
    individuals.size
  end

  def import_families(families)
    families.each do |fam|
      marriage = fam.child("MARR")
      marriage_date = marriage&.child_value("DATE")

      family = Family.with_deleted.find_or_initialize_by(gedcom_id: fam.pointer)
      family.update!(
        marriage_date_string: marriage_date,
        marriage_date_parsed: GedcomDate.parse(marriage_date),
        marriage_place_id: Place.find_or_create_named(marriage&.child_value("PLAC"))&.id,
        gedcom_raw_data: { "children" => [ fam.to_raw ] },
        last_imported_at: Time.current
      )

      link_family_members(family, fam)
    end
    families.size
  end

  # Only the memberships this file describes are replaced. Deleting the whole
  # family's members would also remove anyone an archivist added by hand, and
  # family_members carries no provenance to tell them apart.
  def link_family_members(family, fam)
    husband = fam.child_value("HUSB")
    wife = fam.child_value("WIFE")
    children = fam.all("CHIL").filter_map(&:value)

    imported_ids = Individual.where(gedcom_id: [ husband, wife, *children ].compact).ids
    if imported_ids.any?
      # with_deleted: the composite primary key leaves no room for both a
      # tombstoned membership and its re-imported replacement.
      FamilyMember.with_deleted
        .where(family_id: family.id, individual_id: imported_ids)
        .delete_all
    end

    add_member(family, husband, "FATHER", nil)
    add_member(family, wife, "MOTHER", nil)
    children.each_with_index { |xref, index| add_member(family, xref, "CHILD", index) }
  end

  def add_member(family, xref, role, child_order)
    return if xref.blank?

    individual = Individual.find_by(gedcom_id: xref)
    return unless individual

    FamilyMember.create!(family_id: family.id, individual_id: individual.id,
      role: role, child_order: child_order)
  end

  def import_events(individuals)
    individuals.sum do |indi|
      individual = Individual.find_by(gedcom_id: indi.pointer)
      next 0 unless individual

      individual.events.where(event_type: IMPORTED_EVENT_TYPES).delete_all

      EVENT_TAGS.sum do |tag, event_type|
        indi.all(tag).each do |event|
          date = event.child_value("DATE")
          individual.events.create!(
            event_type: event_type,
            date_string: date,
            date_parsed: GedcomDate.parse(date),
            place_id: Place.find_or_create_named(event.child_value("PLAC"))&.id
          )
        end.size
      end
    end
  end

  # GEDCOM name "Given /Surname/" → parts.
  def parse_name(raw)
    return [ nil, nil ] if raw.blank?

    match = raw.match(%r{\A(.*?)/(.*?)/(.*)\z})
    return [ raw.strip.presence, nil ] unless match

    given = "#{match[1].strip} #{match[3].strip}".strip
    [ given.presence, match[2].strip.presence ]
  end
end
