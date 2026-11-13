require "test_helper"

# Edit mode on the chart: forms load into the dialog frame, saves redirect
# back to the chart URL they came from, domain errors re-render the form.
class FamilyTreeEditingTest < ActionDispatch::IntegrationTest
  setup do
    @mutations = FamilyTree::Mutations.new
    @john = Individual.create!(given_name: "John", surname: "Marias", sex: "M", is_tree_root: true)
    @mutations.add_spouse(person_id: @john.id, spouse_data: { givenName: "Mary", surname: "Smith", sex: "F" })
    @mutations.add_child(parent_id: @john.id, parent_family_id: Family.sole.id,
      child_data: { givenName: "Peter", surname: "Marias", sex: "M" })
    @mary = Individual.find_by!(given_name: "Mary")
    @peter = Individual.find_by!(given_name: "Peter")
    @chart = family_tree_chart_path(edit: 1, depth: 2)
  end

  def sign_in_user = sign_in(User.create!(email: "editor@example.com", password: "password123", name: "Editor"))

  test "the edit flag shows a menu on every card for a signed-in user and nothing for a visitor" do
    get family_tree_chart_path(edit: 1)
    assert_response :success
    assert_select ".tree-menu", count: 0
    assert_select ".tree-card", count: 3

    sign_in_user
    get family_tree_chart_path(edit: 1)
    assert_select ".tree-card", count: 3
    assert_select ".tree-menu", count: 3
    assert_select "#person-#{@john.id} .tree-menu a[href=?]", edit_family_tree_person_path(@john, return_to: family_tree_chart_path(edit: 1))
    assert_select "#person-#{@john.id} .tree-menu a[href*='kind=child']"
    assert_select "turbo-frame#tree_form"

    get family_tree_chart_path
    assert_select ".tree-menu", count: 0
  end

  test "forms require a signed-in user" do
    get edit_family_tree_person_path(@john)
    assert_redirected_to new_user_session_path
  end

  test "the edit form is prefilled and a save goes back to the chart" do
    sign_in_user
    get edit_family_tree_person_path(@john, return_to: @chart)
    assert_response :success
    assert_select "turbo-frame#tree_form form[action=?]", family_tree_person_path(@john)
    assert_select "input[name='person[given_name]'][value='John']"

    patch family_tree_person_path(@john), params: {
      return_to: @chart, person: { given_name: "Johann", surname: "Marias", sex: "M", birth_date: "1849", birth_place: "Bremen" }
    }

    assert_redirected_to @chart
    assert_equal "Johann", @john.reload.given_name
    assert_equal "1849", @john.events.find_by(event_type: "BIRTH").date_string
  end

  test "a return address off this site is ignored" do
    sign_in_user
    patch family_tree_person_path(@john), params: { return_to: "https://evil.example/", person: { given_name: "J" } }

    assert_redirected_to family_tree_chart_path(edit: 1)
  end

  test "adding a child puts them in the chosen marriage" do
    sign_in_user
    @mutations.add_spouse(person_id: @john.id, spouse_data: { givenName: "Second", sex: "F" })
    second = FamilyMember.parents.where(individual_id: Individual.find_by!(given_name: "Second").id).pick(:family_id)

    get new_family_tree_person_relative_path(@john, kind: "child")
    assert_select "select[name='family_id'] option", count: 2

    post family_tree_person_relatives_path(@john), params: {
      kind: "child", family_id: second, return_to: @chart, person: { given_name: "Late", sex: "F" }
    }

    assert_redirected_to @chart
    assert FamilyMember.children.exists?(family_id: second, individual_id: Individual.find_by!(given_name: "Late").id)
  end

  test "adding a spouse records the marriage dates" do
    sign_in_user
    post family_tree_person_relatives_path(@peter), params: {
      kind: "spouse", return_to: @chart, marriage_date: "12 JUN 1950", person: { given_name: "Wife", sex: "F" }
    }

    assert_redirected_to @chart
    assert_equal "12 JUN 1950", Family.order(:id).last.marriage_date_string
  end

  test "adding a parent takes the sex from the role" do
    sign_in_user
    post family_tree_person_relatives_path(@john), params: {
      kind: "parent", role: "MOTHER", return_to: @chart, person: { given_name: "Grandma" }
    }

    assert_redirected_to @chart
    assert_equal "F", Individual.find_by!(given_name: "Grandma").sex
    assert FamilyMember.where(individual_id: Individual.find_by!(given_name: "Grandma").id, role: "MOTHER").exists?
  end

  test "linking an existing parent searches by name, then links, and refuses a duplicate" do
    sign_in_user
    stranger = Individual.create!(given_name: "Anna", surname: "Vogt", sex: "F")

    get new_family_tree_person_relative_path(@john, kind: "existing_parent", q: "vogt")
    assert_select "form[action=?] input[name='existing_parent_id'][value=?]", family_tree_person_relatives_path(@john), stranger.id.to_s

    post family_tree_person_relatives_path(@john), params: { kind: "existing_parent", role: "MOTHER", existing_parent_id: stranger.id, return_to: @chart }
    assert_redirected_to @chart
    assert FamilyMember.where(individual_id: stranger.id, role: "MOTHER").exists?

    post family_tree_person_relatives_path(@john), params: { kind: "existing_parent", role: "MOTHER", existing_parent_id: stranger.id, return_to: @chart }
    assert_response :unprocessable_entity
    assert_select "turbo-frame#tree_form .message-error", text: /already/
  end

  test "adding a sibling needs a parent family" do
    sign_in_user
    post family_tree_person_relatives_path(@peter), params: { kind: "sibling", return_to: @chart, person: { given_name: "Anna" } }
    assert_redirected_to @chart
    assert_equal 2, FamilyMember.children.where(family_id: FamilyMember.children.where(individual_id: @peter.id).pick(:family_id)).count

    post family_tree_person_relatives_path(@john), params: { kind: "sibling", return_to: @chart, person: { given_name: "Nobody" } }
    assert_response :unprocessable_entity
    assert_select ".message-error", text: /no parent family/
  end

  test "an unknown kind is a bad request" do
    sign_in_user
    post family_tree_person_relatives_path(@john), params: { kind: "cousin" }
    assert_response :bad_request
  end

  test "deleting confirms first and refuses someone with descendants" do
    sign_in_user
    get delete_family_tree_person_path(@john, return_to: @chart)
    assert_response :success
    assert_select "button", text: "Delete", count: 0
    assert_select ".message-error", text: /has 1 child/

    get delete_family_tree_person_path(@peter, return_to: @chart)
    assert_select "form[action=?] button", family_tree_person_path(@peter), text: "Delete"

    delete family_tree_person_path(@peter), params: { return_to: @chart }
    assert_redirected_to @chart
    assert_nil Individual.find_by(id: @peter.id)
  end
end
