require "test_helper"

class GedcomDateTest < ActiveSupport::TestCase
  test "parses full, month, and year-only dates" do
    assert_equal Date.new(1950, 6, 12), GedcomDate.parse("12 JUN 1950")
    assert_equal Date.new(1950, 6, 1), GedcomDate.parse("JUN 1950")
    assert_equal Date.new(1950, 1, 1), GedcomDate.parse("1950")
  end

  test "strips qualifiers and takes the first date of a range" do
    assert_equal Date.new(1900, 1, 1), GedcomDate.parse("ABT 1900")
    assert_equal Date.new(1900, 1, 1), GedcomDate.parse("BET 1900 AND 1910")
    assert_equal Date.new(1852, 11, 27), GedcomDate.parse("BEF 27 NOV 1852")
  end

  test "returns nil for blanks and unparseable strings" do
    assert_nil GedcomDate.parse(nil)
    assert_nil GedcomDate.parse("  ")
    assert_nil GedcomDate.parse("sometime in spring")
    assert_nil GedcomDate.parse("31 FEB 1900")
  end
end
