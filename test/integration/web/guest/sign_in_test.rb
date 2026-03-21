# frozen_string_literal: true

require "test_helper"

class WebGuestSignInTest < ActionDispatch::IntegrationTest
  test "guest signs in with invalid data" do
    get(web_adapter.new_user__session_url)

    assert_response :ok

    assert_select("h2", "Welcome back")

    params = { user: { email: "foo@", password: "123" } }

    post(web_adapter.user__sessions_url, params:)

    assert_response :unprocessable_entity

    assert_select("h2", "Welcome back")

    assert_select(".notice-text", "Invalid email or password. Please try again.")
  end

  # NOTE: application_controller.rb L30-32 (stale session when user record is deleted)
  # is not tested here. It requires deleting the user row while keeping the session cookie —
  # impossible inside a Rails transactional test (SQLite blocks PRAGMA foreign_keys = OFF
  # inside an open transaction). Covered by manual/system test if needed.

  test "authenticated user visiting sign-in page is redirected to inbox" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.new_user__session_url
    assert_redirected_to web_adapter.task__items_url(member!(user).inbox)
  end

  test "guest signs in with valid data" do
    params = { user: { email: users(:one).email, password: "123123123" } }

    post(web_adapter.user__sessions_url, params:)

    assert_redirected_to web_adapter.task__items_url(workspace_lists(:one_inbox))

    follow_redirect!

    assert_response :ok

    assert_select(".notice-text", "You have successfully signed in!")

    assert User.exists?(email: params.dig(:user, :email), id: session[:user_id])
  end
end
