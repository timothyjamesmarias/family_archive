module Admin
  module Annotations
    # A numbered dot on the photo that opens the annotation's edit form in the
    # popover. Coordinates are fractions of the image, so percentage offsets
    # keep the dot in place at any rendered size; the translate centres it.
    class MarkerComponent < ApplicationComponent
      def initialize(annotation:, number:, href:)
        @annotation = annotation
        @number = number
        @href = href
      end

      def call
        link_to @number, @href,
          style: "left: #{@annotation.left_percent}%; top: #{@annotation.top_percent}%;",
          title: @annotation.annotation_text,
          aria: { label: "Annotation #{@number}" },
          data: {
            turbo_frame: "annotation_form",
            photo_annotations_target: "marker",
            annotation_id: @annotation.id,
            action: "photo-annotations#select annotation-editor#anchor"
          },
          class: "absolute flex size-8 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full border-3 border-white bg-slate-900 text-[13px] font-semibold text-white shadow hover:scale-115 [&.annotation-dot-selected]:border-amber-400"
      end
    end
  end
end
