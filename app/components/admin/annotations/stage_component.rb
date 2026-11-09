module Admin
  module Annotations
    # The photo in an image-sized box, so markers positioned in percentages
    # land on the image. A click on the photo places a new annotation.
    class StageComponent < ApplicationComponent
      def initialize(file:, annotations:)
        @file = file
        @annotations = annotations
      end

      private

      attr_reader :file, :annotations
    end
  end
end
