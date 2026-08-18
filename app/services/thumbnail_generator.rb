# Generates a JPEG thumbnail for an artifact file's stored image.
class ThumbnailGenerator
  SMALL = 150
  MEDIUM = 300
  LARGE = 600
  SIZES = [ SMALL, MEDIUM, LARGE ].freeze

  MAX_SOURCE_SIZE_BYTES = 20 * 1024 * 1024
  QUALITY = 85

  SUPPORTED_MIME_TYPES = %w[
    image/jpeg image/jpg image/png image/gif image/webp image/bmp
  ].to_set.freeze

  def self.supported?(mime_type)
    mime_type.present? && SUPPORTED_MIME_TYPES.include?(mime_type.downcase)
  end

  # Returns { path:, size_spec: } or nil when the source is unsupported or too
  # large to process.
  def generate(file, size = MEDIUM)
    return nil unless self.class.supported?(file.mime_type)
    return nil if file.file_size > MAX_SOURCE_SIZE_BYTES

    # Loaded here rather than at boot so a machine without libvips can still
    # serve every page that never generates a thumbnail.
    require "image_processing/vips"

    source = Tempfile.create([ "thumb-source", File.extname(file.storage_path) ], binmode: true)
    begin
      source.write(Storage.retrieve(file.storage_path))
      source.flush

      thumbnail = ImageProcessing::Vips
        .source(source.path)
        .resize_to_limit(size, size)
        .convert("jpg")
        .saver(quality: QUALITY)
        .call

      path = thumbnail_path(file.storage_path, size)
      Storage.store(File.binread(thumbnail.path), path)
      thumbnail.close!
      { path: path, size_spec: "#{size}x#{size}" }
    ensure
      File.unlink(source.path)
    end
  end

  def delete(path)
    Storage.delete(path) if Storage.exists?(path)
  end

  private

  def thumbnail_path(source_path, size)
    base = source_path.sub(/\.[^.\/]+\z/, "")
    "#{base}_thumb_#{size}x#{size}.jpg"
  end
end
