module Ui
  # Label + control + hint, stacked. The control is the caller's block and
  # must carry the .field-input recipe class; an error message replaces the
  # hint and switches the whole field into its invalid state.
  class FieldComponent < ApplicationComponent
    def initialize(label:, hint: nil, error: nil)
      @label = label
      @hint = hint
      @error = error
    end

    private

    attr_reader :label, :error

    def invalid?
      error.present?
    end

    def message
      error.presence || @hint
    end
  end
end
