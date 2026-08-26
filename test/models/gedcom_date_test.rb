require "test_helper"

class GedcomDateTest < ActiveSupport::TestCase
  test "parses full, month, and year-only dates" do
    assert_equal Date.new(1950, 6, 12), Gedcom::Date.parse("12 JUN 1950")
    assert_equal Date.new(1950, 6, 1), Gedcom::Date.parse("JUN 1950")
    assert_equal Date.new(1950, 1, 1), Gedcom::Date.parse("1950")
  end

  test "strips qualifiers and takes the first date of a range" do
    assert_equal Date.new(1900, 1, 1), Gedcom::Date.parse("ABT 1900")
    assert_equal Date.new(1900, 1, 1), Gedcom::Date.parse("BET 1900 AND 1910")
    assert_equal Date.new(1852, 11, 27), Gedcom::Date.parse("BEF 27 NOV 1852")
  end

  test "returns nil for blanks and unparseable strings" do
    assert_nil Gedcom::Date.parse(nil)
    assert_nil Gedcom::Date.parse("  ")
    assert_nil Gedcom::Date.parse("sometime in spring")
    assert_nil Gedcom::Date.parse("31 FEB 1900")
  end
end
