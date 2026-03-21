# frozen_string_literal: true

require "test_helper"

class WebStaleUserSessionTest < ActionDispatch::IntegrationTest
  test "user with deleted account is redirected with not-found message" do
    # Create a temporary user, sign in, then delete everything
    User::SignUpProcess.perform_now(username: "ephemeral", email: "ephemeral@example.com", password: "123123123", password_confirmation: "123123123") => [ :ok, user ]
    web_adapter.sign_in(user)

    # Delete all records in dependency order to avoid FK violations
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

    # Now session[:user_id] is set but user doesn't exist
    # authenticate_user! sees current_user_id present but Current.user? false
    # and redirects to home_path with an alert
    get task_lists_url

    assert_response :redirect
  end
end
