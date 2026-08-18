# Artifact file storage, addressed by the `storage_path` strings held in the
# database. Files live under public/uploads and are served statically; set
# ASSET_BASE_URL to serve them from a bucket or CDN instead (and swap the
# read/write methods for that backend when the time comes).
module Storage
  FS_BASE_PATH = "/uploads"

  module_function

  def root
    Rails.root.join("public/uploads")
  end

  def asset_base_url
    override = ENV["ASSET_BASE_URL"]
    return override.chomp("/") if override.present?

    FS_BASE_PATH
  end

  # Public URL for a stored file, given the `storage_path` held in the database.
  def asset_url(storage_path)
    "#{asset_base_url}/#{storage_path}"
  end

  def store(io, path)
    absolute = root.join(path)
    FileUtils.mkdir_p(absolute.dirname)
    File.binwrite(absolute, io.respond_to?(:read) ? io.read : io)
    path
  end

  def retrieve(path)
    File.binread(root.join(path))
  end

  def delete(path)
    FileUtils.rm_f(root.join(path))
  end

  def exists?(path)
    File.exist?(root.join(path))
  end
end
