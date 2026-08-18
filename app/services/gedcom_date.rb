# Best-effort GEDCOM date → Date. Handles qualified dates (ABT/BEF/AFT) by
# stripping the qualifier and parsing the remainder; for ranges (BET x AND y)
# takes the first date. Returns nil when unparseable — the original date
# string is always preserved separately.
module GedcomDate
  MONTHS = {
    "JAN" => 1, "FEB" => 2, "MAR" => 3, "APR" => 4, "MAY" => 5, "JUN" => 6,
    "JUL" => 7, "AUG" => 8, "SEP" => 9, "OCT" => 10, "NOV" => 11, "DEC" => 12
  }.freeze

  # Date qualifiers that precede a date; stripped before parsing.
  QUALIFIERS = /\A(ABT|EST|CAL|BEF|AFT|FROM|TO|BET|AND|INT)\s+/i

  module_function

  def parse(input)
    return nil if input.blank?

    text = input.strip.upcase
    text = text.sub(QUALIFIERS, "") while text.match?(QUALIFIERS)
    first_date = text.split(/\s+AND\s+/).first.strip

    parts = first_date.split(/\s+/)
    case parts.size
    when 3 then build_date(parts[2], MONTHS[parts[1]], parts[0])
    when 2 then build_date(parts[1], MONTHS[parts[0]], "1")
    when 1 then parts[0].match?(/\A\d{3,4}\z/) ? build_date(parts[0], 1, "1") : nil
    end
  end

  def build_date(year, month, day)
    return nil unless month && year.match?(/\A\d+\z/) && day.match?(/\A\d+\z/)

    Date.new(year.to_i, month, day.to_i)
  rescue Date::Error
    nil
  end
end
