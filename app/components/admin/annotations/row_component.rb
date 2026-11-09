module Admin
  module Annotations
    # A list row; selecting it highlights its marker, and the reverse.
    class RowComponent < ApplicationComponent
      def initialize(annotation:, number:)
        @annotation = annotation
        @number = number
      end

      private

      attr_reader :annotation, :number
    end
  end
end
