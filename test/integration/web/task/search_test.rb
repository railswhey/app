# frozen_string_literal: true

require "test_helper"

class WebTaskSearchTest < ActionDispatch::IntegrationTest
  test "guest cannot access search" do
    get web_adapter.search__url
    web_adapter.assert_unauthorized_access
  end

  test "user accesses search page" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.search__url
    assert_response :ok
  end

  test "user searches for a task" do
    user = users(:one)
    member!(user)
    create_task(user, name: "Buy groceries")
    web_adapter.sign_in(user)

    get web_adapter.search__url, params: { q: "groceries" }
    assert_response :ok
    assert_select "a", /Buy groceries/
  end

  test "user searches with no results" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.search__url, params: { q: "zzz_nonexistent_zzz" }
    assert_response :ok
  end

  test "user searches and finds a comment" do
    user = users(:one)
    inbox = member!(user).inbox
    task = create_task(user, name: "Searchable task")
    create_comment(user, task, body: "unique_comment_xkcd_42")
    web_adapter.sign_in(user)

    get web_adapter.search__url, params: { q: "unique_comment_xkcd_42" }
    assert_response :ok
    assert_select ".search-result-quote", /unique_comment_xkcd_42/
  end

  test "user does not see comments from another account" do
    user_one = users(:one)
    user_two = users(:two)
    member!(user_one)
    inbox_two = member!(user_two).inbox
    create_comment(user_two, inbox_two, body: "private_comment_zzz_999")
    web_adapter.sign_in(user_one)

    get web_adapter.search__url, params: { q: "private_comment_zzz_999" }
    assert_response :ok
    assert_select ".search-result-quote", { text: /private_comment_zzz_999/, count: 0 }
  end
end
