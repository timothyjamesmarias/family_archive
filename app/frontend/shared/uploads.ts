/** Must match `MAX_FILE_SIZE_BYTES` in `app/models/artifact.rb`. The server
 * rejects anything larger; this only lets Uppy say so before uploading. */
export const MAX_FILE_SIZE = 50 * 1024 * 1024

export const MAX_FILE_SIZE_LABEL = '50MB'

/** Matches the server, which accepts a batch per artifact upload. */
export const MAX_FILES = 10
