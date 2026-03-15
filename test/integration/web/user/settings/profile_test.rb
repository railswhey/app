# frozen_string_literal: true

require "test_helper"

class WebUserProfileTest < ActionDispatch::IntegrationTest
  test "guest cannot access profile" do
    get web_adapter.edit_user__profile_url
    web_adapter.assert_unauthorized_access
  end

  test "user views profile page with username field" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.edit_user__profile_url
    assert_response :ok
    assert_select "input[name='user[username]']"
    assert_select "input[name='user[email]'][disabled]"
  end

  test "user updates password" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    put web_adapter.user__settings_password_url, params: {
      user: {
        current_password: "123123123",
        password: "newpassword1",
        password_confirmation: "newpassword1"
      }
    }
    assert_redirected_to web_adapter.edit_user__profile_url
    follow_redirect!
    assert_select ".notice-text", /password has been updated/
  end

  test "user fails to update with wrong current password" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    put web_adapter.user__settings_password_url, params: {
      user: {
        current_password: "wrongpassword",
        password: "newpassword1",
        password_confirmation: "newpassword1"
      }
    }
    assert_response :unprocessable_entity
  end
end
