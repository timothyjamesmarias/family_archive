require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  test "guests are sent to the sign-in page" do
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  test "signed-in non-admins are turned away" do
    sign_in User.create!(email: "m@example.com", password: "password123", name: "Member")

    get admin_root_path
    assert_redirected_to root_path
  end

  test "admins can reach every section" do
    sign_in create_admin

    [ admin_root_path, admin_individuals_path, admin_families_path, admin_places_path,
      admin_artifacts_path, admin_articles_path, admin_users_path ].each do |path|
      get path
      assert_response :success, "expected #{path} to render"
    end
  end

  test "a published article links to its public page; a draft doesn't" do
    sign_in create_admin
    live = Article.create!(slug: "live", title: "Live", content: "", published_at: 1.hour.ago)
    draft = Article.create!(slug: "draft", title: "Draft", content: "")

    get admin_article_path(live)
    assert_select "a[href='#{article_path("live")}']", "View on site"

    get admin_article_path(draft)
    assert_select "a", text: "View on site", count: 0
  end

  test "an admin cannot delete their own account" do
    admin = create_admin
    sign_in admin

    delete admin_user_path(admin)

    assert User.exists?(admin.id)
  end

  test "saving a new tree root demotes the previous one" do
    sign_in create_admin
    old_root = Individual.create!(given_name: "Old", is_tree_root: true)

    post admin_individuals_path, params: { individual: {
      gedcom_id: "", given_name: "New", surname: "Root", sex: "", is_tree_root: "1"
    } }

    assert_not old_root.reload.is_tree_root?
    assert Individual.find_by(given_name: "New").is_tree_root?
  end
end
