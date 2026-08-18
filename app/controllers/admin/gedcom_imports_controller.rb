module Admin
  class GedcomImportsController < BaseController
    MAX_GEDCOM_BYTES = 50 * 1024 * 1024

    def show
      @last_result = Rails.cache.read(GedcomImportJob::RESULT_CACHE_KEY)
    end

    def create
      file = params[:file]
      error = validate_gedcom(file)
      if error
        redirect_to admin_gedcom_import_path, alert: error
        return
      end

      # The job unlinks the file when it finishes; deleting it here would race
      # the worker.
      path = stash_upload(file)
      GedcomImportJob.perform_later(path)
      redirect_to admin_gedcom_import_path,
        notice: "Import started — refresh this page for the results."
    end

    private

    def validate_gedcom(file)
      return "Select a GEDCOM file to import" unless file.respond_to?(:original_filename)
      unless File.extname(file.original_filename.to_s).casecmp?(".ged")
        return "The file must be a .ged GEDCOM export"
      end
      return "The file is larger than 50 MB" if file.size > MAX_GEDCOM_BYTES

      nil
    end

    def stash_upload(file)
      dir = Rails.root.join("tmp/gedcom")
      FileUtils.mkdir_p(dir)
      path = dir.join("#{SecureRandom.uuid}.ged")
      File.binwrite(path, file.read)
      path.to_s
    end
  end
end
