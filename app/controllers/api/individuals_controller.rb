module Api
  class IndividualsController < BaseController
    def show
      individual = Individual.includes(events: :place).find_by(id: params[:id])
      unless individual
        return render json: { error: "Individual not found" }, status: :not_found
      end

      render json: FamilyTree.individual_response(individual)
    end

    def roots
      roots = FamilyTree::Builder.new.root_individuals
      with_events = Individual.includes(events: :place).where(id: roots.map(&:id))
      render json: with_events.map { |individual| FamilyTree.individual_response(individual) }
    end
  end
end
