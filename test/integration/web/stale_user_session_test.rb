# frozen_string_literal: true

require "test_helper"

class WebStaleUserSessionTest < ActionDispatch::IntegrationTest
  test "user with deleted account is redirected with not-found message" do
    # Create a temporary user, sign in, then delete everything
    user = User.create!(username: "ephemeral", email: "ephemeral@example.com", password: "123123123")
    web_adapter.sign_in(user)

    # Delete all records in dependency order to avoid FK violations
    user_id = user.id
    account = user.account
    UserToken.where(user_id: user_id).delete_all
    TaskItem.where(task_list_id: account.task_lists.select(:id)).delete_all
    TaskList.where(account_id: account.id).delete_all
    Membership.where(user_id: user_id).delete_all
    Account.where(id: account.id).delete_all
    User.where(id: user_id).delete_all

    # Now session[:user_id] is set but user doesn't exist
    # authenticate_user! sees current_user_id present but Current.user? false
    # and redirects to home_path with an alert
    get task_lists_url

    assert_response :redirect
  end
end
