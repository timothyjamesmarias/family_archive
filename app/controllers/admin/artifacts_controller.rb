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
      scope = Artifact.order(uploaded_at: :desc).includes(:files)
      scope = scope.of_type(params[:artifact_type]) if params[:artifact_type].present?
      scope = search(scope) if params[:q].present?
      @artifacts = Pagination.paginate(
        scope, page: params.fetch(:page, 1), per_page: PER_PAGE
      )
    end

    def show
      @artifact = Artifact.includes(files: :annotations).find(params[:id])
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
        @artifact = Artifact.new(artifact_params.except(:artifact_type))
        flash.now[:alert] = error
        return render :new, status: :unprocessable_entity
      end

      artifact = ArtifactUploader.new.upload(
        files: files,
        artifact_type: type.key,
        title: params.dig(:artifact, :title).presence,
        original_date_string: params.dig(:artifact, :original_date_string).presence
      )
      redirect_to admin_artifact_path(artifact), notice: "Artifact uploaded."
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

    # Deleting only the row would orphan every stored file and thumbnail.
    def destroy
      ArtifactDeletion.new.destroy_artifact(params[:id].to_i)
      redirect_to admin_artifacts_path, notice: "Artifact deleted."
    end

    def add_files
      files = uploaded_files
      error = validate_upload(files)
      if error
        redirect_to admin_artifact_path(params[:id]), alert: error
        return
      end

      ArtifactUploader.new.add_files(params[:id].to_i, files)
      redirect_to admin_artifact_path(params[:id]), notice: "Files added."
    rescue DomainError => e
      redirect_to admin_artifact_path(params[:id]), alert: e.message
    end

    def destroy_file
      ArtifactDeletion.new.destroy_file(params[:id].to_i, params[:file_id].to_i)
      redirect_to admin_artifact_path(params[:id]), notice: "File deleted."
    rescue DomainError => e
      redirect_to admin_artifact_path(params[:id]), alert: e.message
    end

    private

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
