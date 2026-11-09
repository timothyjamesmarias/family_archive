module Admin
  module Annotations
    # The popover's form. It submits inside the annotation_form frame, so a
    # 422 re-renders here; the coordinates ride along as hidden fields.
    class FormComponent < ApplicationComponent
      def initialize(file:, annotation:)
        @file = file
        @annotation = annotation
      end

      private

      attr_reader :file, :annotation

      def heading
        annotation.persisted? ? "Edit annotation" : "Add annotation"
      end

      def editor_path
        annotations_admin_artifact_path(file.artifact_id, file: file.id)
      end
    end
  end
end
