module Admin
  # System utilities screen for bulk thumbnail work. All operations enqueue
  # jobs; nothing runs inline.
  class ThumbnailsController < BaseController
    def show
      @stats = ThumbnailBackfill.new.stats
    end

    def backfill
      result = run_with_size { |size| ThumbnailBackfill.new.backfill_all(size) }
      redirect_to admin_thumbnails_path, notice: result
    end

    def regenerate
      result = run_with_size { |size| ThumbnailBackfill.new.regenerate_all(size) }
      redirect_to admin_thumbnails_path, notice: result
    end

    private

    def run_with_size
      size = requested_size
      unless size
        return "Size must be one of #{ThumbnailGenerator::SIZES.join(', ')}"
      end

      result = yield(size)
      "Enqueued #{result[:jobs_enqueued]} of #{result[:total_artifacts]} " \
        "(#{result[:skipped]} skipped as too large)."
    end

    # Rejects an unsupported size rather than quietly producing a different
    # size than asked for.
    def requested_size
      raw = params[:size]
      return ThumbnailGenerator::MEDIUM if raw.blank?

      size = raw.to_i
      ThumbnailGenerator::SIZES.include?(size) ? size : nil
    end
  end
end
