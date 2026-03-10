# frozen_string_literal: true

require "test_helper"

class WebUserSettingsTest < ActionDispatch::IntegrationTest
  test "guest cannot access settings" do
    get web_adapter.settings__url
    web_adapter.assert_unauthorized_access
  end

  test "user accesses settings hub" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.settings__url
    assert_response :ok
    assert_select "h2", "Settings"
    assert_select ".settings-card", minimum: 3
  end

  test "user accesses profile page" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.edit_user__profile_url
    assert_response :ok
    assert_select "input[name='user[username]']"
  end

  test "user updates profile page" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.edit_user__profile_url
    assert_response :ok
  end

  test "user accesses token page" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.edit_user__token_url
    assert_response :ok
  end

  test "user accesses account page" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.account__url
    assert_response :ok
  end
end
