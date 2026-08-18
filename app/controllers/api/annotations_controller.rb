module Api
  class AnnotationsController < BaseController
    before_action :require_authenticated_user!

    def replace
      incoming = annotation_params.map do |annotation|
        {
          id: annotation[:id],
          annotation_text: annotation[:annotationText].to_s,
          x_coord: annotation[:xCoord],
          y_coord: annotation[:yCoord]
        }
      end

      saved = ReplaceAnnotations.new.call(params[:file_id].to_i, incoming)
      render json: {
        annotations: saved.map do |annotation|
          {
            id: annotation.id,
            annotationText: annotation.annotation_text,
            xCoord: annotation.x_coord.to_f,
            yCoord: annotation.y_coord.to_f
          }
        end
      }
    end

    private

    # Coordinates are stored as fractions of the image's width and height.
    def annotation_params
      annotations = params[:annotations]
      unless annotations.is_a?(ActionController::Parameters) || annotations.is_a?(Array)
        raise InvalidArgumentError.new("annotations is required", field: "annotations")
      end

      Array(annotations).map do |annotation|
        x = Float(annotation[:xCoord], exception: false)
        y = Float(annotation[:yCoord], exception: false)
        text = annotation[:annotationText].to_s
        if text.strip.empty? || x.nil? || y.nil? || !x.between?(0, 1) || !y.between?(0, 1)
          raise InvalidArgumentError.new("Invalid annotation", field: "annotations")
        end

        { id: annotation[:id].presence, annotationText: text.strip, xCoord: x, yCoord: y }
      end
    end
  end
end
