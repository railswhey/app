# frozen_string_literal: true

require "test_helper"

# Tests that all sidebar-linked pages work right after login
# (no task list in context yet). These caught real crashes where
# Current.task_list_id or Current.account was nil.
class WebNavigationTest < ActionDispatch::IntegrationTest
  test "task lists index works right after login" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.task__lists_url
    assert_response :ok
  end

  test "my tasks works right after login" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.my__tasks_url
    assert_response :ok
  end

  test "search works right after login" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.search__url
    assert_response :ok
  end

  test "notifications works right after login" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.notifications__url
    assert_response :ok
  end

  test "settings works right after login" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.settings__url
    assert_response :ok
  end

  test "account page works right after login" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.account__url
    assert_response :ok
  end

  test "search with query works right after login" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.search__url, params: { q: "test" }
    assert_response :ok
  end

  test "navigating all sidebar pages sequentially works" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    # Hit every sidebar link in order — none should crash
    get web_adapter.task__lists_url
    assert_response :ok

    get web_adapter.my__tasks_url
    assert_response :ok

    get web_adapter.search__url
    assert_response :ok

    get web_adapter.notifications__url
    assert_response :ok

    get web_adapter.settings__url
    assert_response :ok

    get web_adapter.account__url
    assert_response :ok
  end
end
