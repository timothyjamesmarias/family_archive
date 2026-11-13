# Shared by the chart's edit forms: a signed-in user, a return address on
# this site, person fields in the shape Individual::Editor and
# FamilyTree::Mutations already speak, and domain errors re-rendered into
# the form at 422 so the dialog shows them in place.
module TreeEditing
  extend ActiveSupport::Concern

  PERSON_FIELDS = %i[given_name surname sex birth_date birth_place death_date death_place].freeze

  DATE_HINT = "Use the archive's form: 12 JUN 1849, JUN 1849 or 1849, with ABT, BEF or AFT in front if unsure."

  included do
    before_action :authenticate_user!
    helper_method :person, :return_to, :person_values, :errors

    rescue_from DomainError do |error|
      @error = error.message
      render_form(status: :unprocessable_entity)
    end
  end

  private

  def errors = @errors || {}

  # Dates are stored as written, so anything Gedcom::Date cannot read would
  # sit in the archive as text forever. Refuse it here, field by field.
  def valid_dates?(values)
    @errors = values.select { |_, value| value.present? && Gedcom::Date.parse(value).nil? }.transform_values { DATE_HINT }
    @error = "One or more dates could not be read." if @errors.any?
    @errors.empty?
  end

  def person
    @person ||= Individual.includes(events: :place).find(params[:person_id] || params[:id])
  end

  def return_to
    url_from(params[:return_to]) || family_tree_path(edit: 1)
  end

  # What the form showed: the submitted values on a 422, else nothing.
  def person_values
    values = params.fetch(:person, {}).permit(*PERSON_FIELDS).to_h.symbolize_keys.transform_values { |value| value.to_s.strip }
    values[:sex] = values[:sex].in?(%w[M F]) ? values[:sex] : "" if values.key?(:sex)
    values
  end

  def person_data
    person_values.transform_keys { |key| key.to_s.camelize(:lower).to_sym }
  end
end
