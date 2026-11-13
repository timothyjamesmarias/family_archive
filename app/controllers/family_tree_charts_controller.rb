# The server-rendered family tree. Everything the chart shows is named in the
# URL: `up[]` and `down[]` are people whose parents or children to load, and
# `depth` is how many generations each way from the roots.
class FamilyTreeChartsController < ApplicationController
  DEPTHS = { nil => 1, "2" => 2, "3" => 3, "all" => FamilyTree::Chart::ALL }.freeze

  def show
    @up = ids(params[:up])
    @down = ids(params[:down])
    @depth = DEPTHS.fetch(params[:depth], 1)
    # A visitor with ?edit=1 just gets the chart.
    @mode = params[:edit].present? && user_signed_in? ? :edit : :view
    @chart = FamilyTree::Chart.new(up: @up, down: @down, depth: @depth)
  end

  private

  def ids(values)
    Array(values).filter_map { |value| value.to_s[/\A\d+\z/]&.to_i }
  end
end
