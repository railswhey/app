# frozen_string_literal: true

require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test ".authorize! with user_id" do
    user = users(:one)

    create_task_list(member!(user).account, name: "Foo")

    Current.authorize!(user_id: user.id)

    assert_predicate Current, :authorized?

    assert_equal member!(user).account.id, Current.account_id
    assert_equal member!(user).inbox.id, Current.task_list_id

    assert_equal member!(user).account, Current.account
    assert_equal member!(user).inbox, Current.task_list
    assert_equal user, Current.user

    assert_equal member!(user).workspace.lists, Current.task_lists
    assert_equal 2, Current.task_lists.size

    assert_predicate Current, :user?
    assert_predicate Current, :account?
    assert_predicate Current, :task_list_id?
    assert_predicate Current, :task_list?

    # ---

    user_id = User.maximum(:id) + 1

    Current.authorize!(user_id:)

    assert_not_predicate Current, :authorized?

    assert_nil Current.user
    assert_nil Current.account_id
    assert_nil Current.task_list_id
  end

  test ".authorize! with user_id and account_id" do
    user = users(:one)
    account = accounts(:one)

    Current.authorize!(user_id: user.id, account_id: account.id)

    assert_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_equal account.id, Current.account_id
    workspace = ::Workspace.find_by!(uuid: account.uuid)
    assert_equal workspace.inbox.id, Current.task_list_id

    # ---

    Current.authorize!(user_id: user.id, account_id: accounts(:two).id)

    assert_not_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_nil Current.account_id
    assert_nil Current.task_list_id

    # ---

    user_id = User.maximum(:id) + 1

    Current.authorize!(user_id:, account_id: account.id)

    assert_not_predicate Current, :authorized?

    assert_nil Current.user
    assert_nil Current.account_id
    assert_nil Current.task_list_id
  end

  test ".authorize! with user_id and task_list_id" do
    user = users(:one)
    account = member!(user).account
    task_list = create_task_list(account, name: "Foo")

    Current.authorize!(user_id: user.id, task_list_id: task_list.id)

    assert_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_equal task_list.id, Current.task_list_id
    assert_equal account.id, Current.account_id

    # ---

    Current.authorize!(user_id: user.id, task_list_id: workspace_lists(:two_inbox).id)

    assert_not_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_equal account.id, Current.account_id
    assert_equal workspace_lists(:two_inbox).id, Current.task_list_id

    # ---

    user_id = User.maximum(:id) + 1

    Current.authorize!(user_id:, task_list_id: task_list.id)

    assert_not_predicate Current, :authorized?

    assert_nil Current.user
    assert_nil Current.account_id
    assert_equal task_list.id, Current.task_list_id
  end

  test ".authorize! with user_id, account_id, and task_list_id" do
    user = users(:one)
    account = accounts(:one)
    task_list = create_task_list(account, name: "Foo")

    Current.authorize!(user_id: user.id, account_id: account.id, task_list_id: task_list.id)

    assert_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_equal account.id, Current.account_id
    assert_equal task_list.id, Current.task_list_id

    # ---

    Current.authorize!(user_id: user.id, account_id: accounts(:two).id, task_list_id: task_list.id)

    assert_not_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_nil Current.account_id
    assert_equal task_list.id, Current.task_list_id

    # ---

    task_list_id = workspace_lists(:two_inbox).id

    Current.authorize!(user_id: user.id, account_id: account.id, task_list_id:)

    assert_not_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_equal account.id, Current.account_id
    assert_equal task_list_id, Current.task_list_id
  end

  test ".authorize! with user_token" do
    user = users(:one)
    user_token = get_user_token(user)

    Current.authorize!(user_token:)

    assert_predicate Current, :authorized?

    assert_equal member!(user).account.id, Current.account_id
    assert_equal member!(user).inbox.id, Current.task_list_id
    assert_equal user, Current.user

    # ---

    Current.authorize!(user_token: SecureRandom.hex)

    assert_not_predicate Current, :authorized?

    assert_nil Current.user
    assert_nil Current.account_id
    assert_nil Current.task_list_id
  end

  test ".authorize! with user_token and account_id" do
    user = users(:one)
    account = accounts(:one)
    user_token = get_user_token(user)

    Current.authorize!(user_token:, account_id: account.id)

    assert_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_equal account.id, Current.account_id
    workspace = ::Workspace.find_by!(uuid: account.uuid)
    assert_equal workspace.inbox.id, Current.task_list_id

    # ---

    Current.authorize!(user_token:, account_id: accounts(:two).id)

    assert_not_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_nil Current.account_id
    assert_nil Current.task_list_id

    # ---

    Current.authorize!(user_token: SecureRandom.hex, account_id: account.id)

    assert_not_predicate Current, :authorized?

    assert_nil Current.user
    assert_nil Current.account_id
    assert_nil Current.task_list_id
  end

  test ".authorize! with user_token and task_list_id" do
    user = users(:one)
    account = member!(user).account
    task_list = create_task_list(account, name: "Foo")
    user_token = get_user_token(user)

    Current.authorize!(user_token:, task_list_id: task_list.id)

    assert_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_equal task_list.id, Current.task_list_id
    assert_equal account.id, Current.account_id

    # ---

    Current.authorize!(user_token:, task_list_id: workspace_lists(:two_inbox).id)

    assert_not_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_equal account.id, Current.account_id
    assert_equal workspace_lists(:two_inbox).id, Current.task_list_id

    # ---

    Current.authorize!(user_token: SecureRandom.hex, task_list_id: task_list.id)

    assert_not_predicate Current, :authorized?

    assert_nil Current.user
    assert_nil Current.account_id
    assert_equal task_list.id, Current.task_list_id
  end

  test ".authorize! with user_token, account_id, and task_list_id" do
    user = users(:one)
    account = accounts(:one)
    task_list = create_task_list(account, name: "Foo")
    user_token = get_user_token(user)

    Current.authorize!(user_token:, account_id: account.id, task_list_id: task_list.id)

    assert_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_equal account.id, Current.account_id
    assert_equal task_list.id, Current.task_list_id

    # ---

    Current.authorize!(user_token:, account_id: accounts(:two).id, task_list_id: task_list.id)

    assert_not_predicate Current, :authorized?

    assert_equal user, Current.user
    assert_nil Current.account_id
    assert_equal task_list.id, Current.task_list_id

    # ---

    Current.authorize!(user_token: SecureRandom.hex, account_id: account.id, task_list_id: task_list.id)

    assert_not_predicate Current, :authorized?

    assert_nil Current.user
    assert_nil Current.account_id
    assert_equal task_list.id, Current.task_list_id
  end
end
