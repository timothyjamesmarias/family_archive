module Admin
  module Annotations
    # The sidebar: a count, then one row per annotation, numbered like the
    # markers.
    class ListComponent < ApplicationComponent
      def initialize(annotations:)
        @annotations = annotations
      end

      private

      attr_reader :annotations
    end
  end
end
