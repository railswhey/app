# frozen_string_literal: true

require "test_helper"

class WebErrorsRescueTest < ActionDispatch::IntegrationTest
  test "error page renders even when session resumption raises" do
    # Sign in, then delete the user to corrupt the session.
    # current_member! will raise when it can't resolve the user,
    # and try_resume_session should rescue gracefully.
    User::SignUpProcess.perform_now(username: "ghost", email: "ghost@example.com", password: "123123123", password_confirmation: "123123123") => [ :ok, user ]
    web_adapter.sign_in(user)

    user_id = user.id
    account = member!(user).account
    User::Token.where(user_id: user_id).delete_all
    workspace = ::Workspace.find_by!(uuid: account.uuid)
    Workspace::Task.where(workspace_list_id: workspace.lists.select(:id)).delete_all
    Workspace::List.where(workspace_id: workspace.id).delete_all
    Workspace::Member.where(uuid: user.uuid).delete_all
    person = Account::Person.find_by!(uuid: user.uuid)
    Account::Membership.where(person_id: person.id).delete_all
    Account::Person.where(id: person.id).delete_all
    Account.where(id: account.id).delete_all
    Workspace.where(id: workspace.id).delete_all
    User.where(id: user_id).delete_all

    get "/404"
    assert_response :not_found
  end
end
