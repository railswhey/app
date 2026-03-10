# frozen_string_literal: true

require "test_helper"

class WebUserAccountTest < ActionDispatch::IntegrationTest
  test "guest cannot access account page" do
    get web_adapter.account__url
    web_adapter.assert_unauthorized_access
  end

  test "user views account page" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.account__url
    assert_response :ok
  end

  test "user updates account name" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    put web_adapter.account__url, params: { account: { name: "New Name" } }
    assert_redirected_to web_adapter.account__url
    follow_redirect!
    assert_select ".notice-text", /Account updated/
    assert_equal "New Name", user.account.reload.name
  end

  test "user fails to update account with blank name" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    put web_adapter.account__url, params: { account: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "user switches account" do
    user = users(:one)
    member!(user)
    other_account = accounts(:two)
    other_account.memberships.create!(user: user, role: :collaborator)

    web_adapter.sign_in(user)

    post web_adapter.switch__account_url(other_account)
    assert_redirected_to web_adapter.task__items_url(task_lists(:two_inbox))
    follow_redirect!
    assert_select ".notice-text", /Switched to/
  end
end
