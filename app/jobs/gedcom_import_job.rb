# Runs a GEDCOM import and caches the result counts for the admin screen,
# since the work no longer finishes inside the request.
class GedcomImportJob < ApplicationJob
  queue_as :default

  RESULT_CACHE_KEY = "gedcom_import:last_result"

  def perform(file_path)
    result = GedcomImporter.new.import_file(file_path)
    write_result(result)
  rescue StandardError => error
    write_result(success: false, errors: [ error.message ])
    raise
  ensure
    FileUtils.rm_f(file_path)
  end

  private

  def write_result(result)
    Rails.cache.write(RESULT_CACHE_KEY, result.merge(finished_at: Time.current))
  end
end
