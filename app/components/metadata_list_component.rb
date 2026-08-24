# The record-pattern <dl>: mono term column, hairline-ruled rows. Values
# come from the row's block so a dd can hold text, chips, or person links.
class MetadataListComponent < ApplicationComponent
  class RowComponent < ApplicationComponent
    def initialize(term:)
      @term = term
    end

    def call
      safe_join([
        tag.dt(@term, class: "field-label pt-3 sm:py-3 border-t border-taupe-100 dark:border-ink-600"),
        tag.dd(content, class: "m-0 text-base text-taupe-900 pt-1 pb-3 sm:py-3 sm:border-t border-taupe-100 flex flex-wrap gap-2 items-center dark:text-ink-50 dark:border-ink-600")
      ])
    end
  end

  renders_many :rows, RowComponent

  def call
    tag.dl(safe_join(rows), class: "m-0 grid grid-cols-[minmax(0,1fr)] sm:grid-cols-[170px_minmax(0,1fr)]")
  end
end
