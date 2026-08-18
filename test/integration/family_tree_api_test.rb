require "test_helper"

class FamilyTreeApiTest < ActionDispatch::IntegrationTest
  setup do
    @root = Individual.create!(given_name: "John", surname: "Marias", sex: "M",
      is_tree_root: true)
  end

  test "initial tree returns the island's payload shape" do
    get "/api/family-tree/initial"

    assert_response :success
    body = response.parsed_body
    individual = body["individuals"].sole
    assert_equal "John", individual["givenName"]
    assert individual["relationships"].key?("hasUnloadedAncestors")
    assert_equal [], body["families"]
  end

  test "expand requires a numeric personId" do
    get "/api/family-tree/expand", params: { personId: "abc" }
    assert_response :bad_request
  end

  test "mutations require an authenticated session" do
    post "/api/family-tree/individuals",
      params: { givenName: "Nope" }, as: :json

    assert_response :unauthorized
    assert_nil Individual.find_by(given_name: "Nope")
  end

  test "an authenticated session can create, expand, and delete" do
    sign_in create_admin

    post "/api/family-tree/individuals",
      params: { givenName: "Ada", surname: "Marias", sex: "F", birthDate: "1815",
                birthPlace: "London" }, as: :json
    assert_response :created
    ada_id = response.parsed_body["id"]
    assert_equal "London", response.parsed_body["birthPlace"]

    post "/api/family-tree/relationships/child",
      params: { parentId: @root.id, childData: { givenName: "Peter" } }, as: :json
    assert_response :created

    get "/api/family-tree/individuals/#{ada_id}/can-delete"
    assert response.parsed_body["valid"]

    delete "/api/family-tree/individuals/#{ada_id}"
    assert_response :no_content
  end

  test "conflicts surface as 409 with the field name" do
    sign_in create_admin
    Individual.create!(gedcom_id: "@I9@", given_name: "Taken")

    post "/api/family-tree/individuals",
      params: { gedcomId: "@I9@", givenName: "Dup" }, as: :json

    assert_response :conflict
    assert response.parsed_body.dig("errors", "gedcomId")
  end

  test "individual roots endpoint serves the surname generation" do
    get "/api/individuals/root"

    assert_response :success
    assert_equal [ "John" ], response.parsed_body.map { |i| i["givenName"] }
  end
end
