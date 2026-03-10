# frozen_string_literal: true

require "test_helper"

class WebUserSignOutTest < ActionDispatch::IntegrationTest
  test "guest signs out" do
    delete(web_adapter.user__sessions_url)

    web_adapter.assert_unauthorized_access
  end

  test "user signs out" do
    user = users(:one)

    web_adapter.sign_in(user)

    delete(web_adapter.user__sessions_url)

    assert_redirected_to web_adapter.new_user__session_url

    follow_redirect!

    assert_response :ok

    assert_select(".notice-text", "You have successfully signed out.")
  end
end
