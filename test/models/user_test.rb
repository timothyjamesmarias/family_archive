require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a name" do
    user = User.new(email: "ada@example.com", password: "password123")

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "only the admin flag grants administration" do
    member = User.create!(email: "m@example.com", password: "password123", name: "Member")
    admin = User.create!(email: "a@example.com", password: "password123", name: "Admin", admin: true)

    assert_not member.can_administer?
    assert admin.can_administer?
  end

  test "rejects duplicate emails" do
    User.create!(email: "ada@example.com", password: "password123", name: "Ada")
    duplicate = User.new(email: "ada@example.com", password: "password123", name: "Other")

    assert_not duplicate.valid?
  end
end
