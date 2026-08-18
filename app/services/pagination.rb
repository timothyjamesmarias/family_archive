# Offset pagination over an Active Record scope, exposing the counters the
# pagination partial renders. Page numbers are 1-based.
class Pagination
  attr_reader :records, :current_page, :per_page, :total

  def self.paginate(scope, page:, per_page:)
    current_page = [ page.to_i, 1 ].max
    total = scope.count(:all)
    records = scope.offset((current_page - 1) * per_page).limit(per_page).to_a
    new(records:, current_page:, per_page:, total:)
  end

  def initialize(records:, current_page:, per_page:, total:)
    @records = records
    @current_page = current_page
    @per_page = per_page
    @total = total
  end

  def last_page
    [ (total.to_f / per_page).ceil, 1 ].max
  end

  def empty?
    records.empty?
  end
end
