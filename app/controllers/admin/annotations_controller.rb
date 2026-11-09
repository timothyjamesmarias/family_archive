module Admin
  class AnnotationsController < BaseController
    before_action :set_file

    def new
      @annotation = @file.annotations.build(x_coord: params[:x], y_coord: params[:y])
    end

    def create
      @annotation = @file.annotations.build(annotation_params)
      if @annotation.save
        redirect_to editor_path, notice: "Annotation added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @annotation = @file.annotations.find(params[:id])
    end

    def update
      @annotation = @file.annotations.find(params[:id])
      if @annotation.update(annotation_params)
        redirect_to editor_path, notice: "Annotation updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @file.annotations.find(params[:id]).destroy!
      redirect_to editor_path, notice: "Annotation deleted."
    end

    private

    def set_file
      @file = ArtifactFile.find(params[:artifact_file_id])
    end

    def editor_path
      annotations_admin_artifact_path(@file.artifact_id, file: @file.id)
    end

    def annotation_params
      params.expect(annotation: [ :annotation_text, :x_coord, :y_coord ])
    end
  end
end
