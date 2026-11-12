module FamilyTree
  # One person on the stage, placed in pixels from their slot and row. The
  # expand links, when given, sit astride the card's top and bottom edges.
  class PersonCardComponent < ApplicationComponent
    def initialize(card:, up_href: nil, down_href: nil, **attributes)
      @card = card
      @up_href = up_href
      @down_href = down_href
      @attributes = attributes
    end

    def person = @card.person
    def dom_id = "person-#{person[:id]}"

    def name
      [ person[:givenName], person[:surname] ].compact_blank.join(" ")
    end

    # Years only, as the design draws them: "1849 – 1921", "b. 1918", "d. 1921".
    def dates
      birth = year(person[:birthDate])
      death = year(person[:deathDate])
      return "#{birth} – #{death}" if birth && death
      return "b. #{birth}" if birth
      "d. #{death}" if death
    end

    # Whole pixels: a slot position can be fractional, a card edge should not be.
    def style
      "left: #{Metrics.left(@card.position.x).round}px; top: #{Metrics.top(@card.position.generation)}px"
    end

    private

    def year(date_string) = date_string&.[](/\d{4}/)
  end
end
