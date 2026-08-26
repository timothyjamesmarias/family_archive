class ArticlesController < ApplicationController
  PER_PAGE = 12

  def index
    @articles = Pagination.paginate(
      Article.published.order(published_at: :desc),
      page: params.fetch(:page, 1), per_page: PER_PAGE
    )
  end

  def show
    @article = Article.find_by(slug: params[:slug])
    raise ActiveRecord::RecordNotFound unless @article&.published?
  end
end
