# The S3 service has no folder option — the blob key IS the object path — so
# new keys are generated under this prefix. Existing keys stay as stored;
# variants land under variants/<prefix>/… because Rails prepends "variants/".
prefix = ENV["AWS_S3_KEY_PREFIX"]

if prefix.present?
  ActiveSupport.on_load(:active_storage_blob) do
    define_method(:key) do
      self[:key] ||= "#{prefix}/#{self.class.generate_unique_secure_token(length: ActiveStorage::Blob::MINIMUM_TOKEN_LENGTH)}"
    end
  end
end
