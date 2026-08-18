module Admin
  class ArticlesController < BaseController
    PER_PAGE = 20
    SEARCH_COLUMNS = %w[title slug excerpt].freeze

    def index
      scope = Article.order(updated_at: :desc)
      scope = search(scope) if params[:q].present?
      @articles = Pagination.paginate(
        scope, page: params.fetch(:page, 1), per_page: PER_PAGE
      )
    end

    def show
      @article = Article.find(params[:id])
    end

    def new
      @article = Article.new
    end

    def create
      @article = Article.new(article_params)
      if @article.save
        redirect_to admin_article_path(@article), notice: "Article created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @article = Article.find(params[:id])
    end

    def update
      @article = Article.find(params[:id])
      if @article.update(article_params)
        redirect_to admin_article_path(@article), notice: "Article updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      Article.find(params[:id]).destroy
      redirect_to admin_articles_path, notice: "Article deleted."
    end

    def publish
      Article.find(params[:id]).publish!
      redirect_to admin_article_path(params[:id]), notice: "Article published."
    end

    def unpublish
      Article.find(params[:id]).unpublish!
      redirect_to admin_article_path(params[:id]), notice: "Article unpublished."
    end

    private

    def search(scope)
      pattern = "%#{Article.sanitize_sql_like(params[:q])}%"
      clauses = SEARCH_COLUMNS.map { |column| "#{column} ILIKE :pattern" }.join(" OR ")
      scope.where(clauses, pattern: pattern)
    end

    # Body HTML is sanitized on the way in — the public page renders it
    # unescaped.
    def article_params
      attributes = params.expect(article: [ :slug, :title, :excerpt, :content, :published_at ])
      attributes.merge(
        content: ArticleHtml.sanitize(attributes[:content]),
        published_at: attributes[:published_at].presence
      )
    end
  end
end
