class Place < ApplicationRecord
  before_validation { self.normalized_name = self.class.normalize(name) if name.present? }

  validates :name, presence: true
  validates :normalized_name, uniqueness: { message: "already exists for another place" },
                              allow_nil: true

  # The dedupe key: every writer (admin form, find_or_create_named) normalizes
  # through here, or lookups miss.
  def self.normalize(name)
    name.strip.downcase
  end

  # Find-or-create by normalized name; display name keeps the original text.
  def self.find_or_create_named(place_name)
    return nil if place_name.blank?

    normalized = normalize(place_name)
    find_by(normalized_name: normalized) ||
      create!(name: place_name.strip, normalized_name: normalized)
  end
end
