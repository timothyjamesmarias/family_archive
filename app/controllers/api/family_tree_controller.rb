module Api
  class FamilyTreeController < BaseController
    def initial
      render json: tree.initial_tree
    end

    def expand
      person_id = params[:personId].to_s
      unless person_id.match?(/\A\d+\z/)
        return render json: { error: "personId is required" }, status: :bad_request
      end

      render json: tree.expand_tree(
        person_id.to_i,
        generations_up: params.fetch(:generationsUp, 0).to_i,
        generations_down: params.fetch(:generationsDown, 0).to_i,
        include_siblings: params[:includeSiblings] == "true"
      )
    end

    private

    def tree
      FamilyTree::Builder.new
    end
  end
end
