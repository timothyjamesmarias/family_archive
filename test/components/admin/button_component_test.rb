require "test_helper"

class Admin::ButtonComponentTest < ViewComponent::TestCase
  test "href renders a link, to renders a button_to form, neither renders a button" do
    render_inline(Admin::ButtonComponent.new(variant: :secondary, href: "/back").with_content("Back"))
    assert_selector "a[href='/back'].border", text: "Back"

    render_inline(Admin::ButtonComponent.new(variant: :danger, to: "/thing", method: :delete).with_content("Delete"))
    assert_selector "form[action='/thing'] input[name=_method][value=delete]", visible: :all
    assert_selector "form button.text-red-700", text: "Delete"

    render_inline(Admin::ButtonComponent.new(type: "submit").with_content("Save"))
    assert_selector "button[type=submit].bg-slate-900", text: "Save"
  end
end
