require "test_helper"

class PlaceTest < ActiveSupport::TestCase
  test "find_or_create_named dedupes on the normalized name" do
    first = Place.find_or_create_named("Chicago, Illinois")
    second = Place.find_or_create_named("  chicago, illinois ")

    assert_equal first.id, second.id
    assert_equal "Chicago, Illinois", first.name
    assert_equal "chicago, illinois", first.normalized_name
  end

  test "blank names produce no place" do
    assert_nil Place.find_or_create_named(nil)
    assert_nil Place.find_or_create_named("   ")
  end

  test "saving derives the normalized name" do
    place = Place.create!(name: "Athens, Greece")

    assert_equal "athens, greece", place.normalized_name
  end
end
