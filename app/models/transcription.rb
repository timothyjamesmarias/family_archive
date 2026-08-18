class Transcription < ApplicationRecord
  belongs_to :artifact
  has_many :translations, dependent: :destroy
end
