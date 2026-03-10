# frozen_string_literal: true

require "test_helper"

class WebErrorsRescueTest < ActionDispatch::IntegrationTest
  test "error page renders even when session resumption raises" do
    # Sign in, then delete the user to corrupt the session.
    # current_member! will raise when it can't resolve the user,
    # and try_resume_session should rescue gracefully.
    user = User.create!(username: "ghost", email: "ghost@example.com", password: "123123123")
    web_adapter.sign_in(user)

    user_id = user.id
    account = user.account
    UserToken.where(user_id: user_id).delete_all
    TaskItem.where(task_list_id: account.task_lists.select(:id)).delete_all
    TaskList.where(account_id: account.id).delete_all
    Membership.where(user_id: user_id).delete_all
    Account.where(id: account.id).delete_all
    User.where(id: user_id).delete_all

    get "/404"
    assert_response :not_found
  end
end
