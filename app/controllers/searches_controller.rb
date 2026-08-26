# Placeholder endpoint so the designed search entry points have a
# destination. The search feature itself is unbuilt and will be architected
# separately — no querying happens here yet.
class SearchesController < ApplicationController
  def show
    @query = params[:q].to_s.strip
  end
end
