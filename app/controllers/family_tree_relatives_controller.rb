# Add a relative to a person from the chart's dialog: a new child, spouse,
# parent or sibling, or an existing person linked as a parent. The kind is
# a parameter so one form flow serves all five; the mutations are untouched.
class FamilyTreeRelativesController < ApplicationController
  include TreeEditing

  KINDS = %w[child spouse parent sibling existing_parent].freeze
  SEX_FOR_ROLE = { "FATHER" => "M", "MOTHER" => "F" }.freeze

  helper_method :kind, :role, :families, :candidates

  def new
    render_form
  end

  NOTICES = {
    "child" => "Child added", "spouse" => "Spouse added", "parent" => "Parent added",
    "sibling" => "Sibling added", "existing_parent" => "Parent linked"
  }.freeze

  def create
    return render_form(status: :unprocessable_entity) unless valid_dates?(dates)

    case kind
    when "child"
      mutations.add_child(parent_id: person.id, child_data: person_data, parent_family_id: params[:family_id].presence)
    when "spouse"
      mutations.add_spouse(person_id: person.id, spouse_data: person_data,
        marriage_data: { marriageDateString: params[:marriage_date].presence, divorceDateString: params[:divorce_date].presence })
    when "parent"
      mutations.add_parent(child_id: person.id, role:, parent_data: person_data.merge(sex: SEX_FOR_ROLE[role]))
    when "sibling"
      mutations.add_sibling(person_id: person.id, sibling_data: person_data)
    when "existing_parent"
      mutations.link_existing_parent(child_id: person.id, existing_parent_id: params[:existing_parent_id].to_i, role:)
    end

    redirect_to return_to, status: :see_other, notice: "#{NOTICES.fetch(kind)} for #{person.display_name}."
  end

  private

  def kind
    KINDS.include?(params[:kind]) ? params[:kind] : raise(ActionController::BadRequest, "unknown kind")
  end

  def role = params[:role].to_s

  def mutations = FamilyTree::Mutations.new

  def dates
    person_values.slice(:birth_date, :death_date).merge(marriage_date: params[:marriage_date], divorce_date: params[:divorce_date])
  end

  def render_form(status: :ok)
    render :new, status:
  end

  # The marriages a new child could belong to.
  def families
    Family.joins(:members).merge(FamilyMember.parents.where(individual_id: person.id)).includes(members: :individual).distinct
  end

  # Existing people matching the search box, for linking as a parent.
  def candidates
    query = params[:q].to_s.strip
    return Individual.none if query.blank?
    pattern = "%#{Individual.sanitize_sql_like(query)}%"
    Individual.where("given_name ILIKE :q OR surname ILIKE :q", q: pattern).where.not(id: person.id).order(:surname, :given_name).limit(20)
  end
end
