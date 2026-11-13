module FamilyTree
  # The fields a person has on the chart: names, sex, birth and death with
  # their places. Prefilled from an existing person, overridden by what a
  # rejected submission sent back; `except` drops fields the flow decides
  # itself (a new parent's sex follows the role).
  class PersonFieldsComponent < ApplicationComponent
    SEXES = { "M" => "Male", "F" => "Female", "" => "Unknown" }.freeze

    def initialize(values: {}, person: nil, except: [], errors: {})
      @values = values
      @person = person
      @except = except
      @errors = errors
    end

    def show?(field) = @except.exclude?(field)
    def error(field) = @errors[field]

    def value(field)
      @values.fetch(field) { prefill[field] }
    end

    private

    def prefill
      @prefill ||= @person ? person_prefill : {}
    end

    def person_prefill
      birth = event("BIRTH")
      death = event("DEATH")
      {
        given_name: @person.given_name, surname: @person.surname, sex: @person.sex,
        birth_date: birth&.date_string, birth_place: birth&.place&.name,
        death_date: death&.date_string, death_place: death&.place&.name
      }
    end

    def event(type) = @person.events.find { |event| event.event_type == type }
  end
end
