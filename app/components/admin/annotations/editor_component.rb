module Admin
  module Annotations
    # One file's annotation editor: the photo with its markers beside the
    # list, and the popover frame that new/edit load into.
    class EditorComponent < ApplicationComponent
      # Escape and clicks outside the photo close the popover; a save inside
      # it refreshes the page.
      ACTIONS = %w[
        click@window->annotation-editor#dismiss
        keydown.esc@window->annotation-editor#close
        turbo:submit-end->annotation-editor#refresh
      ].join(" ").freeze

      def initialize(file:)
        @file = file
      end

      private

      attr_reader :file

      def annotations
        @annotations ||= file.annotations.sort_by(&:id)
      end
    end
  end
end
