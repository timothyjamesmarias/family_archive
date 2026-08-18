class IndividualEvent < ApplicationRecord
  EVENT_TYPES = %w[
    BIRTH DEATH BAPTISM BURIAL MARRIAGE DIVORCE OCCUPATION RESIDENCE
    EMIGRATION IMMIGRATION NATURALIZATION EDUCATION MILITARY CENSUS
    CHRISTENING CONFIRMATION ORDINATION ADOPTION OTHER
  ].freeze

  belongs_to :individual
  belongs_to :place, optional: true

  validates :event_type, inclusion: { in: EVENT_TYPES }
end
