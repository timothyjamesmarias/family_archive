module Ui
  # Mono numbered pager over the Pagination service. Shows first, last, and
  # a window around the current page, with ellipses where the range breaks.
  # Emits nothing for a single page; an optional noun renders a total count.
  class PaginationComponent < ApplicationComponent
    WINDOW = 2

    def initialize(page:, base_url:, noun: nil, extra_params: {})
      @page = page
      @base_url = base_url
      @noun = noun
      @extra_params = extra_params
    end

    def render?
      last_page > 1
    end

    private

    attr_reader :page, :base_url

    delegate :current_page, :last_page, to: :page

    def cells
      visible = (1..last_page).select { |n| n == 1 || n == last_page || (n - current_page).abs <= WINDOW }
      visible.flat_map.with_index do |n, index|
        gap = index.positive? && n > visible[index - 1] + 1
        [ (:ellipsis if gap), n ].compact
      end
    end

    def url_for_page(number)
      "#{base_url}?#{@extra_params.merge(page: number).to_query}"
    end

    def count_label
      "#{page.total} #{@noun.pluralize(page.total)}" if @noun
    end
  end
end
