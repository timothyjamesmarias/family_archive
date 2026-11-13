# Edit and delete a person from the chart's dialog.
class FamilyTreePeopleController < ApplicationController
  include TreeEditing

  def edit
    render_form
  end

  def update
    Individual::Editor.new.update_from_request(person.id, person_data)
    redirect_to return_to, status: :see_other, notice: "#{person.display_name} updated."
  end

  def delete
    render_form
  end

  def destroy
    Individual::Editor.new.soft_delete(person.id)
    redirect_to return_to, status: :see_other, notice: "#{person.display_name} deleted."
  end

  private

  TEMPLATE_FOR = { "update" => :edit, "destroy" => :delete }.freeze

  def render_form(status: :ok)
    @deletion = Individual::Editor.new.can_delete(person.id)
    render TEMPLATE_FOR.fetch(action_name, action_name), status:
  end
end
