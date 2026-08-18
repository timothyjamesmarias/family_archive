module Api
  class FamilyTreeEditsController < BaseController
    before_action :require_authenticated_user!, except: :can_delete

    def create_individual
      render json: editor.create_from_request(individual_params), status: :created
    end

    def update_individual
      render json: editor.update_from_request(params[:id].to_i, individual_params)
    end

    def destroy_individual
      deleted = editor.soft_delete(params[:id].to_i)
      return render json: { errors: { id: "Individual not found" } }, status: :not_found unless deleted

      head :no_content
    end

    def can_delete
      render json: editor.can_delete(params[:id].to_i)
    end

    def add_child
      render json: mutations.add_child(
        parent_id: required_id(:parentId),
        parent_family_id: params[:parentFamilyId].presence,
        child_data: individual_data(:childData)
      ), status: :created
    end

    def add_spouse
      marriage = params[:marriageData].presence
      render json: mutations.add_spouse(
        person_id: required_id(:personId),
        spouse_data: individual_data(:spouseData),
        marriage_data: marriage && {
          marriageDateString: marriage[:marriageDateString].presence,
          divorceDateString: marriage[:divorceDateString].presence
        }
      ), status: :created
    end

    def add_parent
      render json: mutations.add_parent(
        child_id: required_id(:childId),
        role: required_role,
        parent_data: individual_data(:parentData)
      ), status: :created
    end

    def link_existing_parent
      render json: mutations.link_existing_parent(
        child_id: required_id(:childId),
        existing_parent_id: required_id(:existingParentId),
        role: required_role
      ), status: :created
    end

    def add_sibling
      render json: mutations.add_sibling(
        person_id: required_id(:personId),
        sibling_data: individual_data(:siblingData)
      ), status: :created
    end

    private

    def editor
      IndividualEditor.new
    end

    def mutations
      FamilyTree::Mutations.new
    end

    def required_id(key)
      value = params[key].to_s
      raise InvalidArgumentError.new("#{key} is required", field: key.to_s) unless
        value.match?(/\A\d+\z/)

      value.to_i
    end

    def required_role
      role = params[:role].to_s
      unless FamilyMember::ROLES.include?(role)
        raise InvalidArgumentError.new("Invalid role: #{role}", field: "role")
      end
      role
    end

    def individual_params
      individual_fields(params)
    end

    def individual_data(key)
      data = params[key]
      raise InvalidArgumentError.new("#{key} is required", field: key.to_s) unless data.present?

      individual_fields(data)
    end

    def individual_fields(source)
      sex = source[:sex].presence
      if sex && !Individual::SEXES.include?(sex)
        raise InvalidArgumentError.new("Sex must be M or F", field: "sex")
      end

      {
        gedcomId: source[:gedcomId].presence&.strip,
        givenName: source[:givenName].presence&.strip,
        surname: source[:surname].presence&.strip,
        sex: sex,
        birthDate: source[:birthDate].presence&.strip,
        birthPlace: source[:birthPlace].presence&.strip,
        deathDate: source[:deathDate].presence&.strip,
        deathPlace: source[:deathPlace].presence&.strip
      }
    end
  end
end
