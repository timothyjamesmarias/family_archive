module Admin
  class ArtifactsController < BaseController
    PER_PAGE = 20
    SEARCH_COLUMNS = %w[title slug].freeze

    UPLOAD_EXTENSIONS = %w[
      jpg jpeg png gif webp tif tiff
      pdf txt doc docx
      mp3 wav m4a
      mp4 mov webm
    ].freeze

    def index
      @type_page = ArtifactType::BY_ROUTE_SEGMENT[params[:segment]]
      type_key = @type_page&.key || params[:artifact_type].presence

      scope = Artifact.order(uploaded_at: :desc).includes(files: { file_attachment: { blob: :variant_records } })
      scope = scope.of_type(type_key) if type_key
      scope = search(scope) if params[:q].present?
      @artifacts = Pagination.paginate(
        scope, page: params.fetch(:page, 1), per_page: PER_PAGE
      )
    end

    def show
      @artifact = Artifact.includes(files: [ :annotations, { file_attachment: { blob: :variant_records } } ]).find(params[:id])
    end

    # Artifacts are only created by uploading files — a record without a stored
    # file has no meaning.
    def new
      @artifact = Artifact.new
    end

    def create
      files = uploaded_files
      error = validate_upload(files)
      type = ArtifactType.from_string(params.dig(:artifact, :artifact_type))
      error ||= "Choose an artifact type" unless type

      if error
        return respond_to do |format|
          format.html do
            @artifact = Artifact.new(artifact_params.except(:artifact_type))
            flash.now[:alert] = error
            render :new, status: :unprocessable_entity
          end
          format.json { render json: { errors: { files: error } }, status: :unprocessable_entity }
        end
      end

      artifact = Artifact::Uploader.new.upload(
        files: files,
        artifact_type: type.key,
        title: params.dig(:artifact, :title).presence,
        original_date_string: params.dig(:artifact, :original_date_string).presence
      )
      respond_to do |format|
        format.html { redirect_to admin_artifact_path(artifact), notice: "Artifact uploaded." }
        format.json { render json: { data: { id: artifact.id } }, status: :created }
      end
    end

    def edit
      @artifact = Artifact.find(params[:id])
    end

    def update
      @artifact = Artifact.find(params[:id])
      attributes = artifact_params
      unless ArtifactType.from_string(attributes[:artifact_type])
        flash.now[:alert] = "Choose an artifact type"
        return render :edit, status: :unprocessable_entity
      end

      if @artifact.update(attributes)
        redirect_to admin_artifact_path(@artifact), notice: "Artifact updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      Artifact.find(params[:id]).destroy!
      redirect_to admin_artifacts_path, notice: "Artifact deleted."
    end

    def add_files
      files = uploaded_files
      error = validate_upload(files)
      if error
        redirect_to admin_artifact_path(params[:id]), alert: error
        return
      end

      Artifact::Uploader.new.add_files(params[:id].to_i, files)
      redirect_to admin_artifact_path(params[:id]), notice: "Files added."
    rescue DomainError => e
      redirect_to admin_artifact_path(params[:id]), alert: e.message
    end

    def destroy_file
      Artifact.includes(:files).find(params[:id]).remove_file!(params[:file_id])
      redirect_to admin_artifact_path(params[:id]), notice: "File deleted."
    rescue DomainError => e
      redirect_to admin_artifact_path(params[:id]), alert: e.message
    end

    def annotations
      @artifact = Artifact.includes(files: [ :annotations, { file_attachment: { blob: :variant_records } } ])
                          .find(params[:id])
      @payload = annotations_payload(@artifact)
    end

    private

    # The shape the annotations editor island expects; mirrors the Adonis
    # /api/admin/artifacts/:id/annotations payload, with `url` in place of
    # `storagePath` now that files live in Active Storage.
    def annotations_payload(artifact)
      {
        id: artifact.id,
        title: artifact.title,
        slug: artifact.slug,
        artifactType: artifact.artifact_type,
        files: artifact.files.select { |file| file.file.attached? }.map do |file|
          {
            id: file.id,
            url: url_for(file.file),
            mimeType: file.file.blob.content_type,
            fileSequence: file.file_sequence,
            annotations: file.annotations.map do |annotation|
              {
                id: annotation.id,
                annotationText: annotation.annotation_text,
                xCoord: annotation.x_coord.to_f,
                yCoord: annotation.y_coord.to_f
              }
            end
          }
        end
      }
    end

    def search(scope)
      pattern = "%#{Artifact.sanitize_sql_like(params[:q])}%"
      clauses = SEARCH_COLUMNS.map { |column| "#{column} ILIKE :pattern" }.join(" OR ")
      scope.where(clauses, pattern: pattern)
    end

    def uploaded_files
      Array(params[:files]).select { |file| file.respond_to?(:original_filename) }
    end

    def validate_upload(files)
      return "At least one file is required" if files.empty?

      invalid = files.find { |file| !allowed_upload?(file) }
      return "#{invalid.original_filename} is not an allowed file type or is too large" if invalid

      nil
    end

    def allowed_upload?(file)
      extension = File.extname(file.original_filename.to_s).delete_prefix(".").downcase
      UPLOAD_EXTENSIONS.include?(extension) && file.size <= Artifact::MAX_FILE_SIZE_BYTES
    end

    def artifact_params
      params.expect(artifact: [ :artifact_type, :title, :original_date_string ])
    end
  end
end
